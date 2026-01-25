# Contributing to Advanced SQL Project

First off, thank you for considering contributing to this project! 🎉

## How Can I Contribute?

### 🐛 Reporting Bugs

If you find a bug, please create an issue with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected vs actual behavior
- Your MySQL version
- Any relevant error messages

### 💡 Suggesting Enhancements

We welcome enhancement suggestions! Please create an issue with:
- A clear description of the enhancement
- Why it would be useful
- Example use cases
- Any implementation ideas you have

### 📝 Pull Requests

1. **Fork the repository** and create your branch from `main`
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Add new SQL queries with clear comments
   - Update documentation if needed
   - Follow existing code style

3. **Test your changes**
   - Ensure all SQL scripts run without errors
   - Test on MySQL 8.0+
   - Verify documentation is accurate

4. **Commit your changes**
   ```bash
   git commit -m "Add: brief description of changes"
   ```
   
   Use conventional commit messages:
   - `Add:` for new features
   - `Fix:` for bug fixes
   - `Update:` for updates to existing features
   - `Docs:` for documentation changes

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Provide a clear description
   - Reference any related issues
   - Add screenshots if applicable

## Contribution Ideas

### 🚀 New Features
- Additional advanced SQL queries
- More real-world business scenarios
- Performance benchmarks
- Data visualization examples
- Integration with other tools (Python, R, etc.)

### 📊 Sample Data
- Larger datasets for testing
- Industry-specific examples
- Time-series data examples

### 📚 Documentation
- Translations to other languages
- Video tutorials
- Query explanation diagrams
- Performance optimization guides

### 🧪 Testing
- Query validation scripts
- Performance tests
- Compatibility tests

## Code Style Guidelines

### SQL Code
- Use UPPERCASE for SQL keywords (`SELECT`, `FROM`, `WHERE`)
- Use lowercase for table and column names
- Indent nested queries consistently
- Add comments explaining complex logic
- Use meaningful aliases

Example:
```sql
-- Good
SELECT 
    c.customer_id,
    c.name,
    SUM(s.total_amount) AS total_spent
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id
WHERE s.sale_date >= '2024-01-01'
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;
```

### Documentation
- Use clear, concise language
- Include code examples
- Add headers for easy navigation
- Use markdown formatting properly

## Review Process

1. **Automated Checks**: Code style and syntax validation
2. **Manual Review**: At least one maintainer will review
3. **Testing**: Changes are tested on MySQL 8.0+
4. **Discussion**: Address any feedback or questions
5. **Merge**: Once approved, your PR will be merged!

## Recognition

Contributors will be:
- Added to the contributors list
- Mentioned in release notes
- Given credit in the README (for significant contributions)

## Questions?

Feel free to:
- Open an issue for questions
- Reach out to the maintainer
- Start a discussion in GitHub Discussions (if enabled)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all.

### Expected Behavior

- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Personal or political attacks
- Publishing others' private information

Thank you for contributing! 🙏
