"""
Additional security hardening utilities for Scramble.
Provides rate limiting, session management, and additional security features.
"""

import os
import time
import hashlib
import logging
from typing import Dict, Optional, Any
from collections import defaultdict, deque

# Set up logging
logger = logging.getLogger(__name__)


class RateLimiter:
    """Rate limiter to prevent abuse of file processing operations."""
    
    def __init__(self, max_requests: int = 10, window_seconds: int = 60):
        """Initialize rate limiter.
        
        Args:
            max_requests: Maximum number of requests per window
            window_seconds: Time window in seconds
        """
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests = defaultdict(deque)
    
    def is_allowed(self, identifier: str = "default") -> bool:
        """Check if request is allowed for given identifier.
        
        Args:
            identifier: Unique identifier for the requester
            
        Returns:
            True if request is allowed, False if rate limited
        """
        current_time = time.time()
        request_queue = self.requests[identifier]
        
        # Remove old requests outside the window
        while request_queue and request_queue[0] < current_time - self.window_seconds:
            request_queue.popleft()
        
        # Check if we're under the limit
        if len(request_queue) < self.max_requests:
            request_queue.append(current_time)
            return True
        
        logger.warning(f"Rate limit exceeded for identifier: {identifier}")
        return False
    
    def get_remaining_requests(self, identifier: str = "default") -> int:
        """Get number of remaining requests for identifier.
        
        Args:
            identifier: Unique identifier for the requester
            
        Returns:
            Number of remaining requests
        """
        current_time = time.time()
        request_queue = self.requests[identifier]
        
        # Remove old requests outside the window
        while request_queue and request_queue[0] < current_time - self.window_seconds:
            request_queue.popleft()
        
        return max(0, self.max_requests - len(request_queue))
    
    def reset(self, identifier: str = "default"):
        """Reset rate limit for identifier.
        
        Args:
            identifier: Unique identifier to reset
        """
        if identifier in self.requests:
            del self.requests[identifier]


class FileHashCache:
    """Cache for file hashes to prevent reprocessing identical files."""
    
    def __init__(self, max_size: int = 1000):
        """Initialize hash cache.
        
        Args:
            max_size: Maximum number of cached entries
        """
        self.max_size = max_size
        self.cache = {}
        self.access_order = deque()
    
    def get_file_hash(self, file_path: str) -> str:
        """Get hash of file for caching purposes.
        
        Args:
            file_path: Path to the file
            
        Returns:
            SHA256 hash of the file
        """
        try:
            # Get file stats for quick comparison
            stat = os.stat(file_path)
            file_key = f"{file_path}:{stat.st_size}:{stat.st_mtime}"
            
            if file_key in self.cache:
                # Move to end (most recently used)
                self.access_order.remove(file_key)
                self.access_order.append(file_key)
                return self.cache[file_key]
            
            # Calculate hash
            hash_obj = hashlib.sha256()
            with open(file_path, 'rb') as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_obj.update(chunk)
            
            file_hash = hash_obj.hexdigest()
            
            # Add to cache
            self._add_to_cache(file_key, file_hash)
            
            return file_hash
            
        except Exception as e:
            logger.error(f"Failed to calculate hash for {file_path}: {e}")
            return ""
    
    def _add_to_cache(self, key: str, value: str):
        """Add entry to cache with LRU eviction."""
        if len(self.cache) >= self.max_size:
            # Remove least recently used
            oldest_key = self.access_order.popleft()
            del self.cache[oldest_key]
        
        self.cache[key] = value
        self.access_order.append(key)
    
    def clear(self):
        """Clear the cache."""
        self.cache.clear()
        self.access_order.clear()


class SecurityMonitor:
    """Monitor for security events and suspicious activity."""
    
    def __init__(self):
        """Initialize security monitor."""
        self.suspicious_events = deque(maxlen=1000)  # Keep last 1000 events
        self.blocked_files = set()
        self.warning_threshold = 5  # Number of suspicious events before warning
    
    def log_suspicious_event(self, event_type: str, file_path: str, details: str = ""):
        """Log a suspicious security event.
        
        Args:
            event_type: Type of suspicious event
            file_path: Path to file involved
            details: Additional details about the event
        """
        event = {
            'timestamp': time.time(),
            'type': event_type,
            'file_path': file_path,
            'details': details
        }
        
        self.suspicious_events.append(event)
        
        logger.warning(f"Suspicious event: {event_type} - {file_path} - {details}")
        
        # Check if we should block this file
        recent_events = [e for e in self.suspicious_events 
                        if e['file_path'] == file_path and 
                        time.time() - e['timestamp'] < 300]  # Last 5 minutes
        
        if len(recent_events) >= self.warning_threshold:
            self.blocked_files.add(file_path)
            logger.error(f"File blocked due to suspicious activity: {file_path}")
    
    def is_file_blocked(self, file_path: str) -> bool:
        """Check if file is blocked due to suspicious activity.
        
        Args:
            file_path: Path to check
            
        Returns:
            True if file is blocked, False otherwise
        """
        return file_path in self.blocked_files
    
    def unblock_file(self, file_path: str):
        """Remove file from blocked list.
        
        Args:
            file_path: Path to unblock
        """
        self.blocked_files.discard(file_path)
        logger.info(f"File unblocked: {file_path}")
    
    def get_recent_events(self, minutes: int = 60) -> list:
        """Get recent suspicious events.
        
        Args:
            minutes: Number of minutes back to look
            
        Returns:
            List of recent events
        """
        cutoff_time = time.time() - (minutes * 60)
        return [e for e in self.suspicious_events if e['timestamp'] >= cutoff_time]


class SecurityHardening:
    """Main security hardening class that coordinates all security features."""
    
    def __init__(self):
        """Initialize security hardening."""
        self.rate_limiter = RateLimiter(max_requests=20, window_seconds=60)
        self.file_hash_cache = FileHashCache(max_size=500)
        self.security_monitor = SecurityMonitor()
        
        # Security settings
        self.max_concurrent_operations = 3
        self.current_operations = 0
        
        # Temporary file cleanup
        self.temp_files = set()
    
    def check_rate_limit(self, operation: str = "file_processing") -> bool:
        """Check if operation is rate limited.
        
        Args:
            operation: Type of operation being performed
            
        Returns:
            True if allowed, False if rate limited
        """
        return self.rate_limiter.is_allowed(operation)
    
    def check_file_security(self, file_path: str) -> Optional[str]:
        """Comprehensive file security check.
        
        Args:
            file_path: Path to file to check
            
        Returns:
            Error message if security check fails, None if passes
        """
        # Check if file is blocked
        if self.security_monitor.is_file_blocked(file_path):
            return "File is blocked due to suspicious activity"
        
        # Check rate limiting
        if not self.check_rate_limit("file_access"):
            return "Rate limit exceeded - please wait before processing more files"
        
        # Check concurrent operations
        if self.current_operations >= self.max_concurrent_operations:
            return "Maximum concurrent operations exceeded"
        
        return None
    
    def start_operation(self):
        """Mark start of a file operation."""
        self.current_operations += 1
        logger.debug(f"Started operation. Current operations: {self.current_operations}")
    
    def end_operation(self):
        """Mark end of a file operation."""
        self.current_operations = max(0, self.current_operations - 1)
        logger.debug(f"Ended operation. Current operations: {self.current_operations}")
    
    def register_temp_file(self, file_path: str):
        """Register a temporary file for cleanup.
        
        Args:
            file_path: Path to temporary file
        """
        self.temp_files.add(file_path)
    
    def cleanup_temp_files(self):
        """Clean up all registered temporary files."""
        for temp_file in self.temp_files.copy():
            try:
                if os.path.exists(temp_file):
                    os.remove(temp_file)
                    logger.debug(f"Cleaned up temporary file: {temp_file}")
                self.temp_files.discard(temp_file)
            except Exception as e:
                logger.warning(f"Failed to cleanup temporary file {temp_file}: {e}")
    
    def log_security_event(self, event_type: str, file_path: str, details: str = ""):
        """Log a security event.
        
        Args:
            event_type: Type of security event
            file_path: File involved in event
            details: Additional details
        """
        self.security_monitor.log_suspicious_event(event_type, file_path, details)
    
    def get_security_stats(self) -> Dict[str, Any]:
        """Get current security statistics.
        
        Returns:
            Dictionary with security statistics
        """
        return {
            'current_operations': self.current_operations,
            'max_operations': self.max_concurrent_operations,
            'blocked_files': len(self.security_monitor.blocked_files),
            'recent_events': len(self.security_monitor.get_recent_events(60)),
            'temp_files': len(self.temp_files),
            'cache_size': len(self.file_hash_cache.cache)
        }


# Global security hardening instance
_security_hardening = None


def get_security_hardening() -> SecurityHardening:
    """Get the global security hardening instance.
    
    Returns:
        SecurityHardening instance
    """
    global _security_hardening
    if _security_hardening is None:
        _security_hardening = SecurityHardening()
    return _security_hardening


def cleanup_security():
    """Cleanup security resources."""
    global _security_hardening
    if _security_hardening:
        _security_hardening.cleanup_temp_files()
        _security_hardening = None