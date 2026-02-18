#!/usr/bin/env python3
"""
Comprehensive PR Analysis Tool for soundScapeV3

Analyzes Swift/iOS PRs with deep metrics including:
- Cyclomatic complexity
- Architecture quality
- Code reusability
- Test coverage impact
- Technical debt
- Swift/iOS specific patterns
"""

import os
import sys
import json
import argparse
import subprocess
import re
from pathlib import Path
from typing import Dict, List, Any, Tuple
from collections import defaultdict
import hashlib

# Analysis results structure
class PRAnalysis:
    def __init__(self, pr_number: str, base_ref: str, head_ref: str):
        self.pr_number = pr_number
        self.base_ref = base_ref
        self.head_ref = head_ref
        self.metrics = {
            'basic': {},
            'complexity': {},
            'architecture': {},
            'testing': {},
            'patterns': {},
            'safety': {},
            'soundscape_specific': {},
            'files': {}
        }
        
    def to_dict(self) -> Dict:
        return {
            'pr_number': self.pr_number,
            'base_ref': self.base_ref,
            'head_ref': self.head_ref,
            'metrics': self.metrics
        }

class CodeAnalyzer:
    """Analyzes code for various quality metrics"""
    
    SOUNDSCAPE_COMPONENTS = {
        'AudioEngine': ['AudioEngine.swift', 'BinauralBeatEngine.swift'],
        'Sleep Recording': ['SleepRecordingService.swift', 'SoundEventDetector.swift'],
        'Paywall': ['PaywallService.swift', 'PremiumManager.swift', 'SubscriptionService.swift'],
        'UI': ['View.swift', 'ContentView.swift'],
        'Data': ['Repository.swift', 'DataSource.swift', 'Service.swift'],
        'Insights': ['InsightsService.swift', 'AnalyticsService.swift']
    }
    
    RISK_PATTERNS = {
        'high': [
            r'AVAudioSession\.sharedInstance',
            r'AVAudioRecorder\(',
            r'UserDefaults\.standard',
            r'\.task\s*{',  # Unstructured concurrency
            r'DispatchQueue\.main',  # Unsafe threading
            r'fatalError\(',
            r'try!\s',  # Force try
            r'as!\s',   # Force cast
        ],
        'medium': [
            r'@Published',
            r'@StateObject',
            r'\.onAppear',
            r'FileManager\.default',
            r'NotificationCenter',
            r'Combine',
        ],
        'low': [
            r'print\(',
            r'// TODO',
            r'// FIXME',
        ]
    }
    
    SWIFT_PATTERNS = {
        'good': {
            'Main Actor': r'@MainActor',
            'Async/Await': r'async\s+(throws\s+)?->',
            'Protocol-Oriented': r'protocol\s+\w+',
            'Dependency Injection': r'init\([^)]*\)',
            'Error Handling': r'do\s*{[^}]*try[^}]*}\s*catch',
            'Observable': r'@Observable',
            'Environment': r'@Environment',
        },
        'bad': {
            'Force Unwrap': r'!\s*(?![=])',
            'Force Try': r'try!\s',
            'Force Cast': r'as!\s',
            'ImplicitlyUnwrappedOptional': r':\s*\w+!',
            'Global State': r'static\s+var\s+\w+\s*=',
            'Retain Cycle Risk': r'\[weak\s+self\]',  # Good if present, bad if missing in closures
        }
    }
    
    @staticmethod
    def get_git_diff(base_ref: str, head_ref: str = 'HEAD') -> str:
        """Get git diff between two refs"""
        try:
            result = subprocess.run(
                ['git', 'diff', base_ref, head_ref],
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout
        except subprocess.CalledProcessError as e:
            print(f"Error getting git diff: {e}")
            return ""
    
    @staticmethod
    def get_changed_files(base_ref: str, head_ref: str = 'HEAD') -> List[Dict[str, Any]]:
        """Get list of changed files with stats"""
        try:
            result = subprocess.run(
                ['git', 'diff', '--numstat', base_ref, head_ref],
                capture_output=True,
                text=True,
                check=True
            )
            
            files = []
            for line in result.stdout.strip().split('\n'):
                if not line:
                    continue
                parts = line.split('\t')
                if len(parts) >= 3:
                    added = parts[0] if parts[0] != '-' else '0'
                    deleted = parts[1] if parts[1] != '-' else '0'
                    filepath = parts[2]
                    
                    files.append({
                        'path': filepath,
                        'added': int(added),
                        'deleted': int(deleted),
                        'total_changes': int(added) + int(deleted)
                    })
            
            return files
        except subprocess.CalledProcessError as e:
            print(f"Error getting changed files: {e}")
            return []
    
    @staticmethod
    def analyze_complexity(filepath: str) -> Dict[str, Any]:
        """Analyze cyclomatic complexity using lizard"""
        if not filepath.endswith('.swift'):
            return {}
        
        try:
            result = subprocess.run(
                ['lizard', filepath, '-l', 'swift'],
                capture_output=True,
                text=True
            )
            
            output = result.stdout
            
            # Parse lizard output
            complexity_data = {
                'functions': [],
                'avg_complexity': 0,
                'max_complexity': 0,
                'high_complexity_count': 0,  # Functions with CC > 10
            }
            
            lines = output.split('\n')
            for line in lines:
                # Lizard output format: CC  NLOC  token  PARAM  function@line:file
                if '@' in line and not line.startswith('-') and not line.startswith('='):
                    parts = line.split()
                    if len(parts) >= 5 and parts[0].isdigit():
                        cc = int(parts[0])
                        nloc = int(parts[1])
                        func_info = ' '.join(parts[4:])
                        
                        complexity_data['functions'].append({
                            'name': func_info,
                            'complexity': cc,
                            'nloc': nloc
                        })
                        
                        if cc > 10:
                            complexity_data['high_complexity_count'] += 1
            
            if complexity_data['functions']:
                total_cc = sum(f['complexity'] for f in complexity_data['functions'])
                complexity_data['avg_complexity'] = total_cc / len(complexity_data['functions'])
                complexity_data['max_complexity'] = max(f['complexity'] for f in complexity_data['functions'])
            
            return complexity_data
            
        except Exception as e:
            print(f"Error analyzing complexity for {filepath}: {e}")
            return {}
    
    @staticmethod
    def analyze_code_quality(filepath: str) -> Dict[str, Any]:
        """Analyze code quality metrics"""
        if not os.path.exists(filepath) or not filepath.endswith('.swift'):
            return {}
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            quality_metrics = {
                'total_lines': len(content.split('\n')),
                'code_lines': 0,
                'comment_lines': 0,
                'blank_lines': 0,
                'risk_level': 'low',
                'risk_factors': [],
                'patterns': {'good': {}, 'bad': {}},
                'component': CodeAnalyzer.identify_component(filepath),
            }
            
            # Count line types
            in_multiline_comment = False
            for line in content.split('\n'):
                stripped = line.strip()
                if not stripped:
                    quality_metrics['blank_lines'] += 1
                elif stripped.startswith('//'):
                    quality_metrics['comment_lines'] += 1
                elif '/*' in stripped:
                    quality_metrics['comment_lines'] += 1
                    in_multiline_comment = True
                elif '*/' in stripped:
                    quality_metrics['comment_lines'] += 1
                    in_multiline_comment = False
                elif in_multiline_comment:
                    quality_metrics['comment_lines'] += 1
                else:
                    quality_metrics['code_lines'] += 1
            
            # Analyze risk patterns
            high_risk_count = 0
            medium_risk_count = 0
            
            for risk_level, patterns in CodeAnalyzer.RISK_PATTERNS.items():
                for pattern in patterns:
                    matches = re.findall(pattern, content)
                    if matches:
                        quality_metrics['risk_factors'].append({
                            'level': risk_level,
                            'pattern': pattern,
                            'count': len(matches)
                        })
                        if risk_level == 'high':
                            high_risk_count += len(matches)
                        elif risk_level == 'medium':
                            medium_risk_count += len(matches)
            
            # Determine overall risk level
            if high_risk_count > 3:
                quality_metrics['risk_level'] = 'high'
            elif high_risk_count > 0 or medium_risk_count > 5:
                quality_metrics['risk_level'] = 'medium'
            
            # Analyze Swift patterns
            for pattern_type, patterns in CodeAnalyzer.SWIFT_PATTERNS.items():
                for name, pattern in patterns.items():
                    matches = re.findall(pattern, content)
                    if matches:
                        quality_metrics['patterns'][pattern_type][name] = len(matches)
            
            return quality_metrics
            
        except Exception as e:
            print(f"Error analyzing code quality for {filepath}: {e}")
            return {}
    
    @staticmethod
    def identify_component(filepath: str) -> str:
        """Identify which soundScape component this file belongs to"""
        for component, patterns in CodeAnalyzer.SOUNDSCAPE_COMPONENTS.items():
            for pattern in patterns:
                if pattern in filepath:
                    return component
        
        # Fallback based on path
        if 'Service' in filepath:
            return 'Service Layer'
        elif 'View' in filepath or 'Presentation' in filepath:
            return 'UI Layer'
        elif 'Repository' in filepath or 'DataSource' in filepath:
            return 'Data Layer'
        elif 'Entity' in filepath or 'Domain' in filepath:
            return 'Domain Layer'
        elif 'Test' in filepath:
            return 'Tests'
        
        return 'Other'
    
    @staticmethod
    def calculate_code_duplication(files: List[str]) -> Dict[str, Any]:
        """Calculate code duplication score"""
        # Simple hash-based duplication detection
        line_hashes = defaultdict(list)
        total_lines = 0
        duplicate_lines = 0
        
        for filepath in files:
            if not filepath.endswith('.swift') or not os.path.exists(filepath):
                continue
            
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    
                for line_num, line in enumerate(lines):
                    stripped = line.strip()
                    if len(stripped) > 20 and not stripped.startswith('//'):
                        total_lines += 1
                        line_hash = hashlib.md5(stripped.encode()).hexdigest()
                        line_hashes[line_hash].append((filepath, line_num, line))
            except Exception as e:
                print(f"Error analyzing {filepath}: {e}")
        
        # Count duplicates
        duplication_groups = []
        for line_hash, occurrences in line_hashes.items():
            if len(occurrences) > 1:
                duplicate_lines += len(occurrences)
                duplication_groups.append({
                    'line': occurrences[0][2].strip(),
                    'count': len(occurrences),
                    'files': [f"{f[0]}:{f[1]}" for f in occurrences[:5]]  # Limit to 5
                })
        
        duplication_score = (1 - (duplicate_lines / total_lines)) * 100 if total_lines > 0 else 100
        
        return {
            'total_lines_analyzed': total_lines,
            'duplicate_lines': duplicate_lines,
            'duplication_score': round(duplication_score, 2),
            'top_duplicates': sorted(duplication_groups, key=lambda x: x['count'], reverse=True)[:10]
        }

def analyze_test_coverage(changed_files: List[Dict], test_files: List[str]) -> Dict[str, Any]:
    """Analyze test coverage and testing patterns"""
    swift_files = [f for f in changed_files if f['path'].endswith('.swift') and 'Test' not in f['path']]
    test_file_changes = [f for f in changed_files if f['path'].endswith('.swift') and 'Test' in f['path']]
    
    total_code_lines = sum(f['added'] for f in swift_files)
    total_test_lines = sum(f['added'] for f in test_file_changes)
    
    test_coverage = {
        'code_files_changed': len(swift_files),
        'test_files_changed': len(test_file_changes),
        'code_lines_added': total_code_lines,
        'test_lines_added': total_test_lines,
        'test_to_code_ratio': round(total_test_lines / total_code_lines, 2) if total_code_lines > 0 else 0,
        'coverage_score': 0,
        'untested_components': [],
        'test_quality': 'unknown'
    }
    
    # Calculate coverage score
    if test_coverage['test_to_code_ratio'] >= 0.5:
        test_coverage['coverage_score'] = 90
        test_coverage['test_quality'] = 'excellent'
    elif test_coverage['test_to_code_ratio'] >= 0.3:
        test_coverage['coverage_score'] = 70
        test_coverage['test_quality'] = 'good'
    elif test_coverage['test_to_code_ratio'] >= 0.1:
        test_coverage['coverage_score'] = 50
        test_coverage['test_quality'] = 'moderate'
    else:
        test_coverage['coverage_score'] = 20
        test_coverage['test_quality'] = 'poor'
    
    # Identify untested components
    tested_components = set()
    for test_file in test_file_changes:
        filename = os.path.basename(test_file['path']).replace('Tests.swift', '')
        tested_components.add(filename)
    
    for code_file in swift_files:
        filename = os.path.basename(code_file['path']).replace('.swift', '')
        if filename not in tested_components:
            test_coverage['untested_components'].append(filename)
    
    return test_coverage

def analyze_architecture_quality(files: List[Dict], diff_content: str) -> Dict[str, Any]:
    """Analyze architecture and design patterns"""
    architecture = {
        'solid_principles': {'score': 0, 'violations': []},
        'separation_of_concerns': {'score': 0, 'details': []},
        'dependency_patterns': {'good': [], 'bad': []},
        'architecture_score': 0
    }
    
    # Count files by layer
    layer_distribution = defaultdict(int)
    for f in files:
        if 'Domain' in f['path']:
            layer_distribution['Domain'] += 1
        elif 'Data' in f['path']:
            layer_distribution['Data'] += 1
        elif 'Presentation' in f['path']:
            layer_distribution['Presentation'] += 1
    
    # Check for layer violations in diff
    domain_depends_on_data = len(re.findall(r'Domain.*import.*Data', diff_content))
    domain_depends_on_ui = len(re.findall(r'Domain.*import.*SwiftUI', diff_content))
    
    if domain_depends_on_data > 0:
        architecture['solid_principles']['violations'].append(
            "Domain layer depends on Data layer (DIP violation)"
        )
    if domain_depends_on_ui > 0:
        architecture['solid_principles']['violations'].append(
            "Domain layer depends on UI layer (DIP violation)"
        )
    
    # Analyze dependency injection
    di_patterns = len(re.findall(r'init\([^)]*:\s*\w+Protocol', diff_content))
    architecture['dependency_patterns']['good'].append({
        'pattern': 'Protocol-based DI',
        'count': di_patterns
    })
    
    # Calculate scores
    violation_penalty = len(architecture['solid_principles']['violations']) * 10
    architecture['solid_principles']['score'] = max(0, 100 - violation_penalty)
    
    # Separation of concerns
    if len(layer_distribution) >= 2:
        architecture['separation_of_concerns']['score'] = 80
        architecture['separation_of_concerns']['details'] = dict(layer_distribution)
    else:
        architecture['separation_of_concerns']['score'] = 40
    
    # Overall architecture score
    architecture['architecture_score'] = int(
        (architecture['solid_principles']['score'] + 
         architecture['separation_of_concerns']['score']) / 2
    )
    
    return architecture

def main():
    parser = argparse.ArgumentParser(description='Analyze PR quality metrics')
    parser.add_argument('--pr-number', required=True, help='PR number')
    parser.add_argument('--base-ref', required=True, help='Base branch reference')
    parser.add_argument('--head-ref', required=True, help='Head branch reference')
    parser.add_argument('--output-dir', required=True, help='Output directory for results')
    
    args = parser.parse_args()
    
    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"🔍 Analyzing PR #{args.pr_number}")
    print(f"   Base: {args.base_ref}")
    print(f"   Head: {args.head_ref}")
    
    # Initialize analysis
    analysis = PRAnalysis(args.pr_number, args.base_ref, args.head_ref)
    
    # Get changed files
    changed_files = CodeAnalyzer.get_changed_files(args.base_ref, args.head_ref)
    diff_content = CodeAnalyzer.get_git_diff(args.base_ref, args.head_ref)
    
    print(f"   Changed files: {len(changed_files)}")
    
    # Basic metrics
    total_added = sum(f['added'] for f in changed_files)
    total_deleted = sum(f['deleted'] for f in changed_files)
    total_changes = sum(f['total_changes'] for f in changed_files)
    
    analysis.metrics['basic'] = {
        'files_changed': len(changed_files),
        'lines_added': total_added,
        'lines_deleted': total_deleted,
        'total_changes': total_changes,
        'net_lines': total_added - total_deleted
    }
    
    print(f"   Lines changed: +{total_added} -{total_deleted}")
    
    # Complexity analysis
    print("📊 Analyzing complexity...")
    complexity_metrics = {
        'total_functions': 0,
        'avg_complexity': 0,
        'max_complexity': 0,
        'high_complexity_functions': [],
        'complexity_distribution': {'low': 0, 'medium': 0, 'high': 0}
    }
    
    for file_info in changed_files:
        if file_info['path'].endswith('.swift'):
            file_complexity = CodeAnalyzer.analyze_complexity(file_info['path'])
            if file_complexity and 'functions' in file_complexity:
                complexity_metrics['total_functions'] += len(file_complexity['functions'])
                
                for func in file_complexity['functions']:
                    cc = func['complexity']
                    if cc <= 5:
                        complexity_metrics['complexity_distribution']['low'] += 1
                    elif cc <= 10:
                        complexity_metrics['complexity_distribution']['medium'] += 1
                    else:
                        complexity_metrics['complexity_distribution']['high'] += 1
                        complexity_metrics['high_complexity_functions'].append({
                            'file': file_info['path'],
                            'function': func['name'],
                            'complexity': cc
                        })
    
    if complexity_metrics['total_functions'] > 0:
        all_complexities = []
        for file_info in changed_files:
            if file_info['path'].endswith('.swift'):
                fc = CodeAnalyzer.analyze_complexity(file_info['path'])
                if fc and 'functions' in fc:
                    all_complexities.extend([f['complexity'] for f in fc['functions']])
        
        if all_complexities:
            complexity_metrics['avg_complexity'] = round(sum(all_complexities) / len(all_complexities), 2)
            complexity_metrics['max_complexity'] = max(all_complexities)
    
    analysis.metrics['complexity'] = complexity_metrics
    
    # Architecture analysis
    print("🏗️  Analyzing architecture...")
    analysis.metrics['architecture'] = analyze_architecture_quality(changed_files, diff_content)
    
    # Test coverage analysis
    print("🧪 Analyzing test coverage...")
    test_files = [f for f in changed_files if 'Test' in f['path']]
    analysis.metrics['testing'] = analyze_test_coverage(changed_files, test_files)
    
    # Code reusability
    print("♻️  Analyzing code reusability...")
    swift_files = [f['path'] for f in changed_files if f['path'].endswith('.swift')]
    analysis.metrics['patterns']['reusability'] = CodeAnalyzer.calculate_code_duplication(swift_files)
    
    # File-by-file analysis
    print("📁 Analyzing individual files...")
    for file_info in changed_files:
        if file_info['path'].endswith('.swift'):
            file_metrics = CodeAnalyzer.analyze_code_quality(file_info['path'])
            analysis.metrics['files'][file_info['path']] = {
                **file_info,
                **file_metrics
            }
    
    # SoundScape-specific analysis
    print("🎵 Analyzing SoundScape-specific patterns...")
    soundscape_metrics = {
        'audio_session_changes': len(re.findall(r'AVAudioSession', diff_content)),
        'recording_changes': len(re.findall(r'AVAudioRecorder|SleepRecording', diff_content)),
        'paywall_changes': len(re.findall(r'Paywall|Premium|Subscription', diff_content)),
        'ui_changes': len(re.findall(r'View:|@State|@Binding|@Observable', diff_content)),
        'concurrency_patterns': len(re.findall(r'@MainActor|async|await', diff_content)),
        'affected_features': []
    }
    
    # Identify affected features
    for component, patterns in CodeAnalyzer.SOUNDSCAPE_COMPONENTS.items():
        for file_info in changed_files:
            if any(pattern in file_info['path'] for pattern in patterns):
                soundscape_metrics['affected_features'].append(component)
                break
    
    soundscape_metrics['affected_features'] = list(set(soundscape_metrics['affected_features']))
    analysis.metrics['soundscape_specific'] = soundscape_metrics
    
    # Calculate overall quality score
    scores = {
        'complexity': 100 - min(complexity_metrics['avg_complexity'] * 5, 100),
        'architecture': analysis.metrics['architecture']['architecture_score'],
        'testing': analysis.metrics['testing']['coverage_score'],
        'reusability': analysis.metrics['patterns']['reusability']['duplication_score'],
    }
    
    overall_score = sum(scores.values()) / len(scores)
    
    analysis.metrics['quality_score'] = {
        'overall': round(overall_score, 2),
        'breakdown': scores,
        'grade': 'A' if overall_score >= 90 else 'B' if overall_score >= 80 else 'C' if overall_score >= 70 else 'D' if overall_score >= 60 else 'F'
    }
    
    # Save results
    output_file = output_dir / f'pr-{args.pr_number}-analysis.json'
    with open(output_file, 'w') as f:
        json.dump(analysis.to_dict(), f, indent=2)
    
    print(f"\n✅ Analysis complete!")
    print(f"   Overall Quality Score: {overall_score:.2f}/100 (Grade: {analysis.metrics['quality_score']['grade']})")
    print(f"   Results saved to: {output_file}")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
