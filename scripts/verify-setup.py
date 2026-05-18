#!/usr/bin/env python3

"""
Post-setup verification script for CI/CD & Terraform deployment
Validates that all components are properly configured
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from typing import Dict, List, Tuple

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

class Validator:
    def __init__(self):
        self.checks_passed = 0
        self.checks_failed = 0
        self.project_root = Path(__file__).parent.parent
    
    def log_success(self, message: str):
        print(f"{Colors.GREEN}✓{Colors.END} {message}")
        self.checks_passed += 1
    
    def log_error(self, message: str):
        print(f"{Colors.RED}✗{Colors.END} {message}")
        self.checks_failed += 1
    
    def log_warning(self, message: str):
        print(f"{Colors.YELLOW}⚠{Colors.END} {message}")
    
    def log_info(self, message: str):
        print(f"{Colors.BLUE}ℹ{Colors.END} {message}")
    
    def check_file_exists(self, filepath: str, description: str) -> bool:
        full_path = self.project_root / filepath
        if full_path.exists():
            self.log_success(f"{description}: {filepath}")
            return True
        else:
            self.log_error(f"{description} not found: {filepath}")
            return False
    
    def check_github_workflows(self):
        print(f"\n{Colors.BLUE}=== GitHub Workflows ==={Colors.END}")
        
        self.check_file_exists(
            ".github/workflows/ci-develop.yml",
            "CI Workflow"
        )
        self.check_file_exists(
            ".github/workflows/cd-deploy.yml",
            "CD Workflow"
        )
    
    def check_terraform_files(self):
        print(f"\n{Colors.BLUE}=== Terraform Configuration ==={Colors.END}")
        
        terraform_files = [
            ("terraform/versions.tf", "Terraform versions"),
            ("terraform/variables.tf", "Terraform variables"),
            ("terraform/main.tf", "Terraform main"),
            ("terraform/outputs.tf", "Terraform outputs"),
            ("terraform/terraform.tfvars.example", "Terraform variables example"),
            ("terraform/.gitignore", "Terraform gitignore"),
            ("terraform/README.md", "Terraform documentation"),
        ]
        
        for filepath, description in terraform_files:
            self.check_file_exists(filepath, description)
    
    def check_scripts(self):
        print(f"\n{Colors.BLUE}=== Setup Scripts ==={Colors.END}")
        
        self.check_file_exists(
            "scripts/setup-cicd-aws.sh",
            "AWS setup script (Bash)"
        )
        self.check_file_exists(
            "scripts/setup-cicd-aws.ps1",
            "AWS setup script (PowerShell)"
        )
    
    def check_documentation(self):
        print(f"\n{Colors.BLUE}=== Documentation ==={Colors.END}")
        
        docs = [
            ("CI_CD_SETUP_GUIDE.md", "Setup guide"),
            ("CI_CD_COMPLETE_README.md", "Complete README"),
            ("QUICK_REFERENCE.md", "Quick reference"),
        ]
        
        for filepath, description in docs:
            self.check_file_exists(filepath, description)
    
    def check_docker_files(self):
        print(f"\n{Colors.BLUE}=== Docker Configuration ==={Colors.END}")
        
        dockerfiles = [
            ("back-Ventas_SpringBoot/Springboot-API-REST/Dockerfile", "Ventas API Dockerfile"),
            ("back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO/Dockerfile", "Despacho API Dockerfile"),
            ("front_despacho/Dockerfile", "Frontend Dockerfile"),
            ("docker-compose.yml", "Docker compose"),
        ]
        
        for filepath, description in dockerfiles:
            self.check_file_exists(filepath, description)
    
    def check_aws_cli(self) -> bool:
        print(f"\n{Colors.BLUE}=== AWS CLI Check ==={Colors.END}")
        
        try:
            result = subprocess.run(
                ["aws", "--version"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                self.log_success(f"AWS CLI installed: {result.stdout.strip()}")
                return True
            else:
                self.log_error("AWS CLI error")
                return False
        except FileNotFoundError:
            self.log_error("AWS CLI not found in PATH")
            return False
        except Exception as e:
            self.log_error(f"AWS CLI check failed: {e}")
            return False
    
    def check_aws_credentials(self) -> bool:
        print(f"\n{Colors.BLUE}=== AWS Credentials Check ==={Colors.END}")
        
        try:
            result = subprocess.run(
                ["aws", "sts", "get-caller-identity"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                identity = json.loads(result.stdout)
                self.log_success(f"AWS credentials configured")
                self.log_info(f"Account ID: {identity['Account']}")
                self.log_info(f"User/Role: {identity['Arn']}")
                return True
            else:
                self.log_error("AWS credentials not configured")
                return False
        except Exception as e:
            self.log_error(f"Failed to verify AWS credentials: {e}")
            return False
    
    def check_terraform_cli(self) -> bool:
        print(f"\n{Colors.BLUE}=== Terraform CLI Check ==={Colors.END}")
        
        try:
            result = subprocess.run(
                ["terraform", "--version"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                self.log_success(f"Terraform installed: {result.stdout.split()[1]}")
                return True
            else:
                self.log_error("Terraform error")
                return False
        except FileNotFoundError:
            self.log_warning("Terraform not found in PATH (optional for CI/CD)")
            return False
        except Exception as e:
            self.log_error(f"Terraform check failed: {e}")
            return False
    
    def check_docker_cli(self) -> bool:
        print(f"\n{Colors.BLUE}=== Docker CLI Check ==={Colors.END}")
        
        try:
            result = subprocess.run(
                ["docker", "--version"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                self.log_success(f"Docker installed: {result.stdout.strip()}")
                return True
            else:
                self.log_error("Docker error")
                return False
        except FileNotFoundError:
            self.log_warning("Docker not found in PATH (needed for local testing)")
            return False
        except Exception as e:
            self.log_error(f"Docker check failed: {e}")
            return False
    
    def check_git_config(self) -> bool:
        print(f"\n{Colors.BLUE}=== Git Configuration Check ==={Colors.END}")
        
        try:
            # Check if we're in a git repository
            result = subprocess.run(
                ["git", "rev-parse", "--git-dir"],
                capture_output=True,
                text=True,
                cwd=self.project_root,
                timeout=5
            )
            
            if result.returncode == 0:
                self.log_success("Git repository detected")
                
                # Check remote
                result = subprocess.run(
                    ["git", "remote", "-v"],
                    capture_output=True,
                    text=True,
                    cwd=self.project_root,
                    timeout=5
                )
                if "origin" in result.stdout:
                    self.log_success("Git remote 'origin' configured")
                    return True
                else:
                    self.log_warning("Git remote 'origin' not configured")
                    return False
            else:
                self.log_error("Not a git repository")
                return False
        except Exception as e:
            self.log_error(f"Git check failed: {e}")
            return False
    
    def print_summary(self):
        print(f"\n{Colors.BLUE}{'='*50}{Colors.END}")
        print(f"{Colors.BLUE}Verification Summary{Colors.END}")
        print(f"{Colors.BLUE}{'='*50}{Colors.END}\n")
        
        total = self.checks_passed + self.checks_failed
        
        print(f"Checks Passed: {Colors.GREEN}{self.checks_passed}{Colors.END}")
        print(f"Checks Failed: {Colors.RED}{self.checks_failed}{Colors.END}")
        print(f"Total: {total}\n")
        
        if self.checks_failed == 0:
            print(f"{Colors.GREEN}✓ All checks passed!{Colors.END}\n")
            return 0
        else:
            print(f"{Colors.RED}✗ Some checks failed. Please review above.{Colors.END}\n")
            return 1
    
    def print_next_steps(self):
        print(f"{Colors.BLUE}Next Steps:{Colors.END}\n")
        print("1. Run AWS setup script:")
        print(f"   {Colors.YELLOW}./scripts/setup-cicd-aws.sh{Colors.END}")
        print()
        print("2. Add GitHub Secrets (see output from setup script)")
        print()
        print("3. Initialize Terraform:")
        print(f"   {Colors.YELLOW}cd terraform{Colors.END}")
        print(f"   {Colors.YELLOW}cp terraform.tfvars.example terraform.tfvars{Colors.END}")
        print(f"   {Colors.YELLOW}# Edit terraform.tfvars with your values{Colors.END}")
        print(f"   {Colors.YELLOW}terraform init -backend-config=\"bucket=...\" ...{Colors.END}")
        print()
        print("4. Test workflows:")
        print(f"   {Colors.YELLOW}git checkout develop{Colors.END}")
        print(f"   {Colors.YELLOW}git push origin develop  # Triggers CI{Colors.END}")
        print()
        print("5. For more information:")
        print(f"   {Colors.YELLOW}cat CI_CD_SETUP_GUIDE.md{Colors.END}")
        print(f"   {Colors.YELLOW}cat QUICK_REFERENCE.md{Colors.END}")
        print()

def main():
    print(f"\n{Colors.BLUE}╔════════════════════════════════════════════════╗{Colors.END}")
    print(f"{Colors.BLUE}║  CI/CD & Terraform Setup Verification Script   ║{Colors.END}")
    print(f"{Colors.BLUE}╚════════════════════════════════════════════════╝{Colors.END}\n")
    
    validator = Validator()
    
    # File checks
    validator.check_github_workflows()
    validator.check_terraform_files()
    validator.check_scripts()
    validator.check_documentation()
    validator.check_docker_files()
    
    # CLI checks
    validator.check_aws_cli()
    validator.check_aws_credentials()
    validator.check_terraform_cli()
    validator.check_docker_cli()
    validator.check_git_config()
    
    # Summary
    exit_code = validator.print_summary()
    validator.print_next_steps()
    
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
