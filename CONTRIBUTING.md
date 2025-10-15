# Contributing to Salaar

Thank you for your interest in contributing to the Salaar civic reporting app! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x or higher
- Android Studio / Xcode
- Git
- Supabase account (for testing)

### Setup Development Environment
1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/salaar.git`
3. Navigate to the project: `cd salaar`
4. Install dependencies: `flutter pub get`
5. Create your own Supabase project for testing
6. Configure environment variables in `lib/config/app_config.dart`

## 📋 Development Guidelines

### Code Style
- Follow Dart/Flutter conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Use proper error handling

### Commit Messages
Use clear, descriptive commit messages:
```
feat: add Prabhas-style notification system
fix: resolve overflow issues in community screen
docs: update README with setup instructions
refactor: optimize database queries
```

### Pull Request Process
1. Create a feature branch from `main`
2. Make your changes
3. Add tests if applicable
4. Update documentation if needed
5. Submit a pull request with a clear description

## 🧪 Testing

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Coverage report
flutter test --coverage
```

### Manual Testing Checklist
- [ ] Test on different screen sizes
- [ ] Verify all user roles work correctly
- [ ] Check notification functionality
- [ ] Test offline/online scenarios
- [ ] Validate form inputs and error handling

## 🎯 Areas for Contribution

### High Priority
- **Bug Fixes**: Fix any reported issues
- **Performance**: Optimize app performance and loading times
- **Accessibility**: Improve accessibility features
- **Testing**: Add more comprehensive tests

### Medium Priority
- **New Features**: Add new functionality based on user feedback
- **UI/UX**: Improve user interface and experience
- **Documentation**: Enhance documentation and guides
- **Localization**: Add support for more languages

### Low Priority
- **Code Refactoring**: Clean up and optimize existing code
- **Dependencies**: Update and maintain dependencies
- **CI/CD**: Improve build and deployment processes

## 🔧 Technical Guidelines

### Database Changes
- Always include migration scripts
- Test changes on a copy of production data
- Document schema changes
- Consider backward compatibility

### API Changes
- Maintain backward compatibility when possible
- Document all API changes
- Add proper error handling
- Include rate limiting considerations

### UI Changes
- Follow Material Design guidelines
- Ensure responsive design
- Test on different devices
- Maintain accessibility standards

## 🐛 Reporting Issues

### Bug Reports
When reporting bugs, please include:
- **Description**: Clear description of the issue
- **Steps to Reproduce**: Detailed steps to reproduce the bug
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Environment**: Device, OS version, app version
- **Screenshots**: If applicable

### Feature Requests
For feature requests, please include:
- **Description**: Clear description of the feature
- **Use Case**: Why this feature would be useful
- **Proposed Solution**: How you think it should work
- **Alternatives**: Other solutions you've considered

## 📝 Code of Conduct

### Our Pledge
We are committed to providing a welcoming and inclusive environment for all contributors.

### Expected Behavior
- Be respectful and inclusive
- Accept constructive criticism
- Focus on what's best for the community
- Show empathy towards other community members

### Unacceptable Behavior
- Harassment or discrimination
- Trolling or inflammatory comments
- Personal attacks or political discussions
- Spam or off-topic discussions

## 🏆 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- Project documentation

## 📞 Getting Help

- **GitHub Issues**: For bugs and feature requests
- **Discussions**: For questions and general discussion
- **Email**: Contact the maintainers directly

## 📄 License

By contributing to Salaar, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Salaar! Together, we can build a better civic reporting platform for communities worldwide. 🦁⚡
