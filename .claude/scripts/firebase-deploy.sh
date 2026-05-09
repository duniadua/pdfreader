#!/bin/bash

# Firebase Deployment Script
# Deploys Firebase functions with comprehensive pre-deployment checks

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "firebase.json" ]; then
    log_error "firebase.json not found. Please run from project root."
    exit 1
fi

# Change to functions directory if it exists
if [ -d "functions" ]; then
    cd functions
    log_info "Working in functions/ directory"
else
    log_error "functions/ directory not found"
    exit 1
fi

# Step 1: TypeScript Compilation Check
log_info "Step 1/5: Checking TypeScript compilation..."
if npx tsc --noEmit 2>&1; then
    log_success "TypeScript compilation successful"
else
    log_error "TypeScript compilation failed"
    log_info "Fix the errors above before deploying"
    exit 1
fi

# Step 2: Run Tests
log_info "Step 2/5: Running tests..."
if npm test 2>&1; then
    log_success "All tests passed"
else
    log_error "Tests failed"
    log_info "Fix failing tests before deploying"
    exit 1
fi

# Step 3: Code Formatting Check
log_info "Step 3/5: Checking code formatting..."
if command -v prettier &> /dev/null; then
    if npx prettier --check "**/*.{ts,js,json}" &> /dev/null; then
        log_success "Code formatting check passed"
    else
        log_warning "Code formatting issues found"
        log_info "Run 'npx prettier --write \"**/*.{ts,js,json}\"' to fix"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Deployment cancelled"
            exit 1
        fi
    fi
else
    log_warning "Prettier not found, skipping format check"
fi

# Step 4: Build Functions
log_info "Step 4/5: Building functions..."
if npm run build 2>&1; then
    log_success "Build successful"

    # Check if build output exists
    if [ ! -d "lib" ]; then
        log_error "Build output directory 'lib' not found"
        exit 1
    fi

    # Show build size
    BUILD_SIZE=$(du -sh lib | cut -f1)
    log_info "Build size: $BUILD_SIZE"
else
    log_error "Build failed"
    log_info "Fix build errors before deploying"
    exit 1
fi

# Step 5: Deploy to Firebase
cd ..
log_info "Step 5/5: Deploying to Firebase..."

# Get Firebase project info
PROJECT_ID=$(grep '"projectId"' firebase.json | sed 's/.*"projectId": "\(.*\)".*/\1/')
log_info "Target project: $PROJECT_ID"

# Show functions to be deployed
log_info "Functions to be deployed:"
if [ -f "functions/.firebaserc" ]; then
    cat functions/.firebaserc 2>/dev/null || true
fi

# Confirmation prompt
echo ""
log_warning "About to deploy to Firebase project: $PROJECT_ID"
read -p "Continue with deployment? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Deployment cancelled"
    exit 0
fi

# Deploy
log_info "Starting deployment..."
if firebase deploy --only functions; then
    log_success "Deployment completed successfully!"

    # Show deployment summary
    echo ""
    log_info "Deployment Summary:"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "✓ TypeScript compilation: Passed"
    log_info "✓ Tests: Passed"
    log_info "✓ Build: Successful"
    log_info "✓ Deployment: Complete"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Show function URLs if available
    log_info "Check Firebase Console for function URLs:"
    log_info "https://console.firebase.google.com/project/$PROJECT_ID/functions"

else
    log_error "Deployment failed"
    log_info "Previous functions are still running"
    log_info "Check the error messages above for details"
    exit 1
fi
