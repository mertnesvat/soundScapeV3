#!/usr/bin/env python3
"""
Quality Threshold Checker for PR Assessment

Checks if PR meets minimum quality thresholds and fails the workflow if not
"""

import os
import sys
import json
import argparse
from pathlib import Path
from typing import Dict, Any, List, Tuple

class QualityChecker:
    """Checks PR against quality thresholds"""
    
    # Define quality thresholds
    THRESHOLDS = {
        'minimum_overall_score': 60,  # F grade cutoff
        'minimum_test_coverage_score': 50,  # Must have some tests
        'maximum_avg_complexity': 15,  # Reasonable complexity limit
        'minimum_architecture_score': 60,  # Basic architecture quality
        'maximum_high_risk_files': 10,  # Limit dangerous code
        'minimum_duplication_score': 70,  # Allow some duplication
    }
    
    # Warning thresholds (won't fail, but will warn)
    WARNING_THRESHOLDS = {
        'recommended_overall_score': 80,
        'recommended_test_coverage_score': 70,
        'recommended_avg_complexity': 7,
        'recommended_architecture_score': 80,
        'recommended_high_risk_files': 3,
        'recommended_duplication_score': 85,
    }
    
    def __init__(self, analysis_dir: Path, fail_on_regression: bool = False):
        self.analysis_dir = analysis_dir
        self.fail_on_regression = fail_on_regression
        self.failures = []
        self.warnings = []
        
    def check_analysis(self, analysis: Dict[str, Any]) -> Tuple[bool, List[str], List[str]]:
        """Check analysis against thresholds"""
        metrics = analysis['metrics']
        
        # Check overall score
        overall_score = metrics['quality_score']['overall']
        if overall_score < self.THRESHOLDS['minimum_overall_score']:
            self.failures.append(
                f"Overall score {overall_score:.2f} is below minimum threshold of {self.THRESHOLDS['minimum_overall_score']}"
            )
        elif overall_score < self.WARNING_THRESHOLDS['recommended_overall_score']:
            self.warnings.append(
                f"Overall score {overall_score:.2f} is below recommended threshold of {self.WARNING_THRESHOLDS['recommended_overall_score']}"
            )
        
        # Check test coverage
        test_score = metrics['testing']['coverage_score']
        if test_score < self.THRESHOLDS['minimum_test_coverage_score']:
            self.failures.append(
                f"Test coverage score {test_score} is below minimum threshold of {self.THRESHOLDS['minimum_test_coverage_score']}"
            )
        elif test_score < self.WARNING_THRESHOLDS['recommended_test_coverage_score']:
            self.warnings.append(
                f"Test coverage score {test_score} is below recommended threshold of {self.WARNING_THRESHOLDS['recommended_test_coverage_score']}"
            )
        
        # Check complexity
        avg_complexity = metrics['complexity'].get('avg_complexity', 0)
        if avg_complexity > self.THRESHOLDS['maximum_avg_complexity']:
            self.failures.append(
                f"Average complexity {avg_complexity:.2f} exceeds maximum threshold of {self.THRESHOLDS['maximum_avg_complexity']}"
            )
        elif avg_complexity > self.WARNING_THRESHOLDS['recommended_avg_complexity']:
            self.warnings.append(
                f"Average complexity {avg_complexity:.2f} exceeds recommended threshold of {self.WARNING_THRESHOLDS['recommended_avg_complexity']}"
            )
        
        # Check architecture
        arch_score = metrics['architecture']['architecture_score']
        if arch_score < self.THRESHOLDS['minimum_architecture_score']:
            self.failures.append(
                f"Architecture score {arch_score} is below minimum threshold of {self.THRESHOLDS['minimum_architecture_score']}"
            )
        elif arch_score < self.WARNING_THRESHOLDS['recommended_architecture_score']:
            self.warnings.append(
                f"Architecture score {arch_score} is below recommended threshold of {self.WARNING_THRESHOLDS['recommended_architecture_score']}"
            )
        
        # Check high-risk files
        files = metrics.get('files', {})
        high_risk_count = sum(1 for f in files.values() if f.get('risk_level') == 'high')
        if high_risk_count > self.THRESHOLDS['maximum_high_risk_files']:
            self.failures.append(
                f"High-risk files count {high_risk_count} exceeds maximum threshold of {self.THRESHOLDS['maximum_high_risk_files']}"
            )
        elif high_risk_count > self.WARNING_THRESHOLDS['recommended_high_risk_files']:
            self.warnings.append(
                f"High-risk files count {high_risk_count} exceeds recommended threshold of {self.WARNING_THRESHOLDS['recommended_high_risk_files']}"
            )
        
        # Check duplication
        duplication_score = metrics['patterns']['reusability'].get('duplication_score', 100)
        if duplication_score < self.THRESHOLDS['minimum_duplication_score']:
            self.failures.append(
                f"Duplication score {duplication_score:.2f} is below minimum threshold of {self.THRESHOLDS['minimum_duplication_score']}"
            )
        elif duplication_score < self.WARNING_THRESHOLDS['recommended_duplication_score']:
            self.warnings.append(
                f"Duplication score {duplication_score:.2f} is below recommended threshold of {self.WARNING_THRESHOLDS['recommended_duplication_score']}"
            )
        
        # Check for critical violations
        violations = metrics['architecture']['solid_principles'].get('violations', [])
        if violations:
            for violation in violations:
                if 'Domain layer depends on' in violation:
                    self.failures.append(f"Critical architecture violation: {violation}")
        
        # Check for high complexity functions
        high_cc_functions = metrics['complexity'].get('high_complexity_functions', [])
        critical_cc_functions = [f for f in high_cc_functions if f['complexity'] > 20]
        if critical_cc_functions:
            self.failures.append(
                f"Found {len(critical_cc_functions)} functions with extremely high complexity (>20)"
            )
        
        passed = len(self.failures) == 0
        
        return passed, self.failures, self.warnings
    
    def print_results(self, passed: bool, pr_number: str):
        """Print check results"""
        print("\n" + "="*60)
        print(f"Quality Threshold Check - PR #{pr_number}")
        print("="*60)
        
        if self.failures:
            print("\n❌ FAILURES:")
            for i, failure in enumerate(self.failures, 1):
                print(f"  {i}. {failure}")
        
        if self.warnings:
            print("\n⚠️  WARNINGS:")
            for i, warning in enumerate(self.warnings, 1):
                print(f"  {i}. {warning}")
        
        if passed:
            print("\n✅ All quality thresholds passed!")
        else:
            print(f"\n❌ Quality check failed with {len(self.failures)} failure(s)")
        
        print("="*60 + "\n")
        
        return passed
    
    def run(self) -> int:
        """Run quality checks"""
        # Find analysis file
        analysis_files = list(self.analysis_dir.glob('pr-*-analysis.json'))
        
        if not analysis_files:
            print("❌ No analysis files found")
            return 1
        
        # Load analysis
        analysis_file = analysis_files[0]
        with open(analysis_file, 'r') as f:
            analysis = json.load(f)
        
        pr_number = analysis.get('pr_number', 'Unknown')
        
        # Run checks
        passed, failures, warnings = self.check_analysis(analysis)
        
        # Print results
        self.print_results(passed, pr_number)
        
        # Create GitHub Actions annotations
        if 'GITHUB_ACTIONS' in os.environ:
            # Add warnings
            for warning in warnings:
                print(f"::warning::Quality Warning: {warning}")
            
            # Add errors
            for failure in failures:
                print(f"::error::Quality Check Failed: {failure}")
        
        # Return appropriate exit code
        if not passed:
            if self.fail_on_regression:
                return 1
            else:
                print("⚠️  Quality checks failed but not failing workflow (fail_on_regression=false)")
                return 0
        
        return 0

def main():
    parser = argparse.ArgumentParser(description='Check PR quality thresholds')
    parser.add_argument('--analysis-dir', required=True, help='Directory with analysis results')
    parser.add_argument('--fail-on-regression', type=str, default='false', 
                       help='Whether to fail on quality regressions (true/false)')
    
    args = parser.parse_args()
    
    analysis_dir = Path(args.analysis_dir)
    fail_on_regression = args.fail_on_regression.lower() == 'true'
    
    checker = QualityChecker(analysis_dir, fail_on_regression)
    return checker.run()

if __name__ == '__main__':
    sys.exit(main())
