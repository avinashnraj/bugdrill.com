# GitHub Actions Secrets Configuration

This document lists all the secrets you need to configure in your GitHub repository for the CI/CD pipeline to work.

## Required Secrets

### Docker Hub Authentication

1. **DOCKER_USERNAME**
   - Description: Your Docker Hub username
   - Example: `yourusername`
   - How to get: Your Docker Hub login name

2. **DOCKER_PASSWORD**
   - Description: Docker Hub access token (NOT your password)
   - How to get:
     1. Go to https://hub.docker.com/settings/security
     2. Click "New Access Token"
     3. Give it a description (e.g., "GitHub Actions")
     4. Copy the token (you won't see it again!)

### AWS Deployment (Required for production deployment)

3. **AWS_SSH_PRIVATE_KEY**
   - Description: SSH private key to access your EC2 instance
   - How to get:
     ```bash
     # On your local machine, copy your private key content
     cat ~/.ssh/id_rsa
     ```
   - Paste the ENTIRE content including:
     ```
     -----BEGIN OPENSSH PRIVATE KEY-----
     ...key content...
     -----END OPENSSH PRIVATE KEY-----
     ```

4. **AWS_HOST**
   - Description: Public IP or domain of your EC2 instance
   - Example: `3.91.123.456` or `api.yourdomain.com`
   - How to get: From your Terraform output or AWS console

## How to Add Secrets to GitHub

### Via GitHub Web UI:

1. Go to your repository on GitHub
2. Click "Settings" → "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Add each secret with the exact name listed above
5. Paste the value
6. Click "Add secret"

### Via GitHub CLI:

```bash
# Install GitHub CLI if you haven't: https://cli.github.com/

# Set each secret
gh secret set DOCKER_USERNAME
# Paste your username when prompted

gh secret set DOCKER_PASSWORD
# Paste your token when prompted

gh secret set AWS_SSH_PRIVATE_KEY < ~/.ssh/id_rsa

gh secret set AWS_HOST
# Enter your EC2 IP
```

## Optional Secrets

### Codecov (Optional - for coverage reports)

5. **CODECOV_TOKEN**
   - Description: Token for uploading coverage reports to Codecov
   - How to get:
     1. Go to https://codecov.io/
     2. Sign in with GitHub
     3. Add your repository
     4. Copy the upload token

## Environment Configuration

The CI/CD pipeline uses the "production" environment for AWS deployments. To configure:

1. Go to repository Settings → Environments
2. Create environment named "production"
3. Add protection rules (optional):
   - Required reviewers
   - Wait timer
   - Deployment branches (e.g., only `main`)

## Verifying Secrets

After adding secrets, you can verify they're set up correctly:

```bash
# List all secrets (won't show values)
gh secret list
```

Should show:
```
DOCKER_USERNAME
DOCKER_PASSWORD
AWS_SSH_PRIVATE_KEY
AWS_HOST
```

## Security Best Practices

1. **Never commit secrets** to your repository
2. **Rotate secrets regularly** (every 90 days recommended)
3. **Use least privilege** - Docker tokens should only have push access to your repositories
4. **Monitor secret usage** - Check Actions logs for unauthorized access attempts
5. **Use environment secrets** for production - provides additional protection

## Troubleshooting

### Docker Login Fails
- Verify DOCKER_USERNAME is your exact Docker Hub username
- Ensure DOCKER_PASSWORD is an access token (not your password)
- Check token hasn't expired

### SSH Connection Fails
- Verify AWS_SSH_PRIVATE_KEY includes header and footer
- Ensure the private key matches the public key on your EC2 instance
- Check AWS_HOST is correct and EC2 instance is running
- Verify security group allows SSH from GitHub Actions IPs (or use 0.0.0.0/0)

### Build Fails
- Check the GitHub Actions logs for specific error messages
- Verify all required secrets are set
- Ensure your Docker Hub account has enough space for images

## Next Steps

After configuring secrets:

1. Push code to trigger the CI/CD pipeline
2. Monitor the workflow run in the "Actions" tab
3. Check deployment success in your production environment

For more information, see the [CI/CD documentation](../infrastructure/README.md).
