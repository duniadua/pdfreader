#!/bin/bash
# Hook Manager - Activate/deactivate project hooks
# Usage: .claude/scripts/manage-hooks.sh [command]
# Commands: activate, deactivate, status, list

PROJECT_DIR="/Users/macbook/testclaude"
HOOKS_DIR="$PROJECT_DIR/.claude/hooks"
GIT_DIR="$PROJECT_DIR/.git/hooks"

# Available hooks
declare -a HOOKS=(
    "pre-bash-safety.sh"
    "pre-write-check.sh"
    "pre-test-validate.sh"
    "post-edit-format.sh"
    "post-bash-dependency.sh"
    "post-edit-build-runner.sh"
    "post-write-test-suggest.sh"
    "pre-commit.sh"
    "post-build-apk.sh"
    "pre-git-push.sh"
    "pre-device-connect.sh"
    "pre-firebase-deploy.sh"
    "post-firebase-deploy.sh"
)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    echo "📌 Hook Manager for PDF Reader App"
    echo ""
    echo "Usage: .claude/scripts/manage-hooks.sh [command]"
    echo ""
    echo "Commands:"
    echo "  activate    - Install all hooks to .git/hooks/"
    echo "  deactivate  - Remove all hooks from .git/hooks/"
    echo "  status      - Show which hooks are active"
    echo "  list        - List all available hooks"
    echo "  enable      - Enable specific hook(s)"
    echo "  disable     - Disable specific hook(s)"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  .claude/scripts/manage-hooks.sh activate"
    echo "  .claude/scripts/manage-hooks.sh enable pre-commit"
    echo "  .claude/scripts/manage-hooks.sh disable post-firebase-deploy"
}

list_hooks() {
    echo "📋 Available Hooks:"
    echo ""
    echo "🔒 Pre-Hooks:"
    echo "   pre-bash-safety.sh          - Warn dangerous commands"
    echo "   pre-write-check.sh          - Validate file structure"
    echo "   pre-test-validate.sh        - Check code generation"
    echo "   pre-commit.sh               - Full pre-commit validation"
    echo "   pre-git-push.sh             - Pre-push safety check"
    echo "   pre-device-connect.sh       - Device detection"
    echo "   pre-firebase-deploy.sh      - Firebase deploy check"
    echo ""
    echo "🔓 Post-Hooks:"
    echo "   post-edit-format.sh         - Auto-format edited files"
    echo "   post-bash-dependency.sh     - Track dependency changes"
    echo "   post-edit-build-runner.sh   - Detect build_runner needed"
    echo "   post-write-test-suggest.sh  - Suggest test files"
    echo "   post-build-apk.sh           - Copy APK + notify"
    echo "   post-firebase-deploy.sh     - Log deploy results"
    echo ""
    echo "🔧 Configured Hooks:"
    echo "   pre-session-summary.sh       - Session summary"
    echo "   pre-read-validate.sh        - Validate large reads"
}

show_status() {
    echo "📊 Hook Status:"
    echo ""
    
    local active_count=0
    local total_count=${#HOOKS[@]}
    
    for hook in "${HOOKS[@]}"; do
        hook_name="${hook%.sh}"
        if [ -f "$GIT_DIR/$hook_name" ] || [ -L "$GIT_DIR/$hook_name" ]; then
            echo -e "   ${GREEN}✓${NC} $hook"
            active_count=$((active_count + 1))
        else
            echo -e "   ${RED}✗${NC} $hook"
        fi
    done
    
    echo ""
    echo "Active: $active_count / $total_count"
}

activate_hooks() {
    echo "🔧 Activating hooks..."
    echo ""
    
    # Create .git/hooks directory if needed
    mkdir -p "$GIT_DIR"
    
    for hook in "${HOOKS[@]}"; do
        hook_name="${hook%.sh}"
        source_path="$HOOKS_DIR/$hook"
        target_path="$GIT_DIR/$hook_name"
        
        if [ -f "$source_path" ]; then
            # Remove existing if different
            if [ -f "$target_path" ] || [ -L "$target_path" ]; then
                rm -f "$target_path"
            fi
            
            # Create symlink
            ln -s "$source_path" "$target_path"
            echo -e "   ${GREEN}✓${NC} $hook_name"
        else
            echo -e "   ${RED}✗${NC} $hook_name (source not found)"
        fi
    done
    
    echo ""
    echo "✅ Hooks activated!"
}

deactivate_hooks() {
    echo "🧹 Deactivating hooks..."
    echo ""
    
    for hook in "${HOOKS[@]}"; do
        hook_name="${hook%.sh}"
        target_path="$GIT_DIR/$hook_name"
        
        if [ -f "$target_path" ] || [ -L "$target_path" ]; then
            rm -f "$target_path"
            echo -e "   ${RED}✗${NC} $hook_name"
        fi
    done
    
    echo ""
    echo "✅ Hooks deactivated!"
}

enable_hook() {
    local hook_name="$1"
    local found=false
    
    for hook in "${HOOKS[@]}"; do
        hook_base="${hook%.sh}"
        if [ "$hook_base" = "$hook_name" ]; then
            source_path="$HOOKS_DIR/$hook"
            target_path="$GIT_DIR/$hook_name"
            
            if [ -f "$target_path" ]; then
                echo "   $hook_name already enabled"
            else
                ln -s "$source_path" "$target_path"
                echo -e "   ${GREEN}✓${NC} $hook_name enabled"
            fi
            found=true
            break
        fi
    done
    
    if [ "$found" = false ]; then
        echo -e "   ${RED}✗${NC} Hook not found: $hook_name"
        echo "   Run 'list' to see available hooks"
    fi
}

disable_hook() {
    local hook_name="$1"
    local found=false
    
    for hook in "${HOOKS[@]}"; do
        hook_base="${hook%.sh}"
        if [ "$hook_base" = "$hook_name" ]; then
            target_path="$GIT_DIR/$hook_name"
            
            if [ -f "$target_path" ] || [ -L "$target_path" ]; then
                rm -f "$target_path"
                echo -e "   ${RED}✗${NC} $hook_name disabled"
            else
                echo "   $hook_name already disabled"
            fi
            found=true
            break
        fi
    done
    
    if [ "$found" = false ]; then
        echo -e "   ${RED}✗${NC} Hook not found: $hook_name"
    fi
}

# Main command handler
case "${1:-help}" in
    activate)
        activate_hooks
        ;;
    deactivate)
        deactivate_hooks
        ;;
    status)
        show_status
        ;;
    list)
        list_hooks
        ;;
    enable)
        if [ -z "$2" ]; then
            echo "Usage: manage-hooks.sh enable <hook-name>"
            echo "Example: manage-hooks.sh enable pre-commit"
        else
            enable_hook "$2"
        fi
        ;;
    disable)
        if [ -z "$2" ]; then
            echo "Usage: manage-hooks.sh disable <hook-name>"
            echo "Example: manage-hooks.sh disable post-firebase-deploy"
        else
            disable_hook "$2"
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        ;;
esac
