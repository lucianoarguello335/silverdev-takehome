# Instructions to run script

## Prerequisites Check

Note: These instructions are meant for MacOS. For **Windows or Linux** instructions check: [https://www.ruby-lang.org/en/documentation/installation/](https://www.ruby-lang.org/en/documentation/installation/)

First, verify your system has the required tools:

```bash
# Check Ruby version (should be 2.6+)
ruby --version

# Check if Homebrew is installed (for macOS package management)
brew --version

# Check if Git is installed
git --version

```

## Step 1: Install Ruby (if not already installed)

If Ruby is not installed or is an older version:

```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL <https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh>)"

# Install Ruby using Homebrew
brew install ruby

# Add Ruby to your PATH (add this to your ~/.zshrc or ~/.bash_profile)
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

```

## Step 2: Clone the Repository

```bash
# Navigate to your desired directory, like:
cd ~/Desktop

# Clone the repository
git clone <https://github.com/lucianoarguello335/silverdev-takehome.git>

# Navigate into the project directory
cd silverdev-takehome

```

## Step 3: Install Dependencies

```bash
# Install Bundler (Ruby package manager)
gem install bundler

# Install project dependencies using Bundler
bundle install

```

**Alternative method (if Bundler fails):**

```bash
# Install gems manually
gem install http sqlite3

```

## Step 4: Verify Installation

```bash
# Check if all required gems are installed
ruby -e "require 'http'; require 'sqlite3'; puts 'All dependencies installed successfully!'"

```

## Step 5: Run the API Monitoring Script

### Basic Usage (10 minutes monitoring):

```bash
ruby ApiCheck.rb

```

### Custom Parameters:

```bash
# Monitor for 5 minutes with 2-second intervals
ruby ApiCheck.rb --duration 300 --interval 2

# Use custom name parameter
ruby ApiCheck.rb --name "Jane Smith"

# Use custom URL (if needed)
ruby ApiCheck.rb --url "<https://qa-challenge-nine.vercel.app/api/name-checker>" --name "Test User"

# View all available options
ruby ApiCheck.rb --help

```

## Expected Output

The script will show:

- Real-time monitoring logs
- Request status and response times
- Final summary with success rate
- Database logging of all requests
- Example output in terminal:
    
    ![image.png](Instructions%20to%20run%20script%2023f4a850f6f4804f85f9e0b49ca77335/image.png)
    
- Example “request_logs.db” database after running script:
    
    ![image.png](Instructions%20to%20run%20script%2023f4a850f6f4804f85f9e0b49ca77335/image%201.png)
    

## Common Errors and Solutions

### 1. Ruby Version Issues

**Error:** `ruby: command not found`**Solution:**

```bash
brew install ruby
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

```

### 2. Gem Installation Failures

**Error:** `ERROR: Failed to build gem native extension`**Solution:**

```bash
# Install Xcode command line tools
xcode-select --install

# Try installing gems again
gem install http sqlite3

```

### 3. Permission Issues

**Error:** `Permission denied` or `You don't have write permissions`**Solution:**

```bash
# Use rbenv or rvm for Ruby version management
brew install rbenv
rbenv init
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
source ~/.zshrc
rbenv install 3.2.0
rbenv global 3.2.0

```

### 4. Network/SSL Issues

**Error:** `SSL_connect returned=1 errno=0 state=error`**Solution:**

```bash
# Update certificates
brew install openssl
gem install bundler -- --with-openssl-dir=$(brew --prefix openssl)

```

### 5. Database Lock Issues

**Error:** `database is locked`**Solution:**

```bash
# Remove existing database and restart
rm request_logs.db
ruby ApiCheck.rb

```

### 6. HTTP Timeout Issues

**Error:** `HTTP::TimeoutError`**Solution:**

```bash
# Increase timeout or check network connection
ruby ApiCheck.rb --interval 2

```

## Troubleshooting Commands

```bash
# Check Ruby environment
which ruby
ruby --version
gem env

# Check installed gems
gem list

# Check database file
ls -la request_logs.db

# Test database connection
ruby -e "require 'sqlite3'; db = SQLite3::Database.new('request_logs.db'); puts 'Database OK'"

# Test HTTP connectivity
curl -X POST <https://qa-challenge-nine.vercel.app/api/name-checker> \\
  -H "Content-Type: application/json" \\
  -d '{"name": "Test User"}'

```

## Quick Test Run

For a quick test (1 minute monitoring):

```bash
ruby ApiCheck.rb --duration 60 --interval 1

```

This will run the script for 1 minute, making 60 requests to verify everything is working correctly.

---

**Note:** The script will create a `request_logs.db` SQLite database file that stores all request data.