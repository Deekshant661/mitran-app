class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
  // Validate username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    if (value.length > 20) {
      return 'Username must be less than 20 characters';
    }
    
    final regex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!regex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens';
    }
    
    return null;
  }
  
  // Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numbers.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    return null;
  }
  
  // Validate dog name
  static String? validateDogName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Dog name is required';
    }
    
    if (value.length < 2) {
      return 'Dog name must be at least 2 characters';
    }
    
    if (value.length > 30) {
      return 'Dog name must be less than 30 characters';
    }
    
    return null;
  }
  
  // Validate post content
  static String? validatePostContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Post content cannot be empty';
    }
    
    if (value.length > 500) {
      return 'Post must be less than 500 characters';
    }
    
    return null;
  }
  
  // Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}