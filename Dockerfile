# Use a simple base image
FROM debian:bullseye-slim

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    gnupg \
    ca-certificates \
    build-essential \
    libpq-dev \
    libvips \
    git \
    postgresql-client \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Ruby 3.2.2 using rbenv
RUN curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc && \
    export PATH="$HOME/.rbenv/bin:$PATH" && \
    eval "$(rbenv init -)" && \
    rbenv install 3.2.2 && \
    rbenv global 3.2.2 && \
    gem install bundler

# Set working directory
WORKDIR /rails

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN export PATH="$HOME/.rbenv/bin:$PATH" && \
    eval "$(rbenv init -)" && \
    bundle install

# Copy application code
COPY . .

# Create rails user
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /rails
USER rails:rails

# Set environment
ENV PATH="/home/rails/.rbenv/bin:$PATH"
ENV RAILS_ENV=production

# Entrypoint prepares the database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server
EXPOSE 3000
CMD ["./bin/rails", "server"]
