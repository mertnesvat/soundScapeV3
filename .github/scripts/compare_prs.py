#!/usr/bin/env python3
"""
PR Comparison Tool for soundScapeV3

Compares multiple PRs side-by-side with detailed analysis
"""

import os
import sys
import json
import argparse
from pathlib import Path
from typing import Dict, List, Any

class PRComparator:
    """Compares quality metrics across multiple PRs"""
    
    def __init__(self, output_dir: Path):
        self.output_dir = output_dir
        self.comparisons = {}
        
    def load_pr_analysis(self, pr_number: str) -> Dict[str, Any]:
        """Load analysis results for a PR"""
        analysis_file = self.output_dir / f'pr-{pr_number}-analysis.json'
        if not analysis_file.exists():
            print(f"⚠️  Analysis not found for PR #{pr_number}")
            return None
        
        with open(analysis_file, 'r') as f:
            return json.load(f)
    
    def compare_prs(self, pr_numbers: List[str]) -> Dict[str, Any]:
        """Compare multiple PRs"""
        print(f"🔄 Comparing PRs: {', '.join([f'#{n}' for n in pr_numbers])}")
        
        analyses = {}
        for pr_num in pr_numbers:
            analysis = self.load_pr_analysis(pr_num)
            if analysis:
                analyses[pr_num] = analysis
        
        if len(analyses) < 2:
            print("❌ Need at least 2 PRs to compare")
            return {}
        
        comparison = {
            'prs': list(analyses.keys()),
            'comparison_date': str(Path.cwd()),
            'metrics_comparison': self._compare_metrics(analyses),
            'quality_ranking': self._rank_prs(analyses),
            'recommendations': self._generate_recommendations(analyses),
            'detailed_breakdown': self._detailed_breakdown(analyses)
        }
        
        return comparison
    
    def _compare_metrics(self, analyses: Dict[str, Dict]) -> Dict[str, Any]:
        """Compare key metrics across PRs"""
        comparison = {
            'basic': {},
            'complexity': {},
            'architecture': {},
            'testing': {},
            'quality_scores': {}
        }
        
        # Basic metrics comparison
        for pr_num, analysis in analyses.items():
            basic = analysis['metrics']['basic']
            comparison['basic'][pr_num] = {
                'files_changed': basic['files_changed'],
                'total_changes': basic['total_changes'],
                'net_lines': basic['net_lines']
            }
        
        # Complexity comparison
        for pr_num, analysis in analyses.items():
            complexity = analysis['metrics']['complexity']
            comparison['complexity'][pr_num] = {
                'avg_complexity': complexity.get('avg_complexity', 0),
                'max_complexity': complexity.get('max_complexity', 0),
                'high_complexity_count': len(complexity.get('high_complexity_functions', []))
            }
        
        # Architecture comparison
        for pr_num, analysis in analyses.items():
            arch = analysis['metrics']['architecture']
            comparison['architecture'][pr_num] = {
                'score': arch['architecture_score'],
                'violations': len(arch['solid_principles'].get('violations', []))
            }
        
        # Testing comparison
        for pr_num, analysis in analyses.items():
            testing = analysis['metrics']['testing']
            comparison['testing'][pr_num] = {
                'test_to_code_ratio': testing['test_to_code_ratio'],
                'coverage_score': testing['coverage_score'],
                'test_quality': testing['test_quality']
            }
        
        # Quality scores
        for pr_num, analysis in analyses.items():
            score = analysis['metrics']['quality_score']
            comparison['quality_scores'][pr_num] = {
                'overall': score['overall'],
                'grade': score['grade'],
                'breakdown': score['breakdown']
            }
        
        return comparison
    
    def _rank_prs(self, analyses: Dict[str, Dict]) -> List[Dict[str, Any]]:
        """Rank PRs by quality"""
        rankings = []
        
        for pr_num, analysis in analyses.items():
            overall_score = analysis['metrics']['quality_score']['overall']
            
            # Calculate quality per line changed
            total_changes = analysis['metrics']['basic']['total_changes']
            quality_per_line = overall_score / total_changes if total_changes > 0 else 0
            
            rankings.append({
                'pr_number': pr_num,
                'overall_score': overall_score,
                'quality_per_line': round(quality_per_line, 4),
                'grade': analysis['metrics']['quality_score']['grade'],
                'total_changes': total_changes
            })
        
        # Sort by overall score
        rankings.sort(key=lambda x: x['overall_score'], reverse=True)
        
        # Add rank
        for i, r in enumerate(rankings, 1):
            r['rank'] = i
        
        return rankings
    
    def _generate_recommendations(self, analyses: Dict[str, Dict]) -> Dict[str, Any]:
        """Generate recommendations based on comparison"""
        rankings = self._rank_prs(analyses)
        
        if len(rankings) < 2:
            return {}
        
        best_pr = rankings[0]
        worst_pr = rankings[-1]
        
        best_analysis = analyses[best_pr['pr_number']]
        worst_analysis = analyses[worst_pr['pr_number']]
        
        recommendations = {
            'best_pr': best_pr['pr_number'],
            'best_pr_score': best_pr['overall_score'],
            'reasons_best_is_better': [],
            'improvements_for_others': []
        }
        
        # Compare specific areas
        best_metrics = best_analysis['metrics']
        worst_metrics = worst_analysis['metrics']
        
        # Testing comparison
        if best_metrics['testing']['coverage_score'] > worst_metrics['testing']['coverage_score']:
            diff = best_metrics['testing']['coverage_score'] - worst_metrics['testing']['coverage_score']
            recommendations['reasons_best_is_better'].append({
                'category': 'Testing',
                'reason': f"Better test coverage ({diff:.0f} points higher)",
                'details': f"Test-to-code ratio: {best_metrics['testing']['test_to_code_ratio']} vs {worst_metrics['testing']['test_to_code_ratio']}"
            })
            recommendations['improvements_for_others'].append({
                'pr': worst_pr['pr_number'],
                'category': 'Testing',
                'suggestion': f"Add more tests. Current test-to-code ratio is {worst_metrics['testing']['test_to_code_ratio']}, aim for at least 0.3"
            })
        
        # Complexity comparison
        if best_metrics['complexity']['avg_complexity'] < worst_metrics['complexity']['avg_complexity']:
            diff = worst_metrics['complexity']['avg_complexity'] - best_metrics['complexity']['avg_complexity']
            recommendations['reasons_best_is_better'].append({
                'category': 'Complexity',
                'reason': f"Lower average complexity ({diff:.1f} points lower)",
                'details': f"Avg complexity: {best_metrics['complexity']['avg_complexity']} vs {worst_metrics['complexity']['avg_complexity']}"
            })
            if worst_metrics['complexity'].get('high_complexity_count', 0) > 0:
                recommendations['improvements_for_others'].append({
                    'pr': worst_pr['pr_number'],
                    'category': 'Complexity',
                    'suggestion': f"Refactor {worst_metrics['complexity']['high_complexity_count']} high-complexity functions"
                })
        
        # Architecture comparison
        if best_metrics['architecture']['architecture_score'] > worst_metrics['architecture']['architecture_score']:
            diff = best_metrics['architecture']['architecture_score'] - worst_metrics['architecture']['architecture_score']
            recommendations['reasons_best_is_better'].append({
                'category': 'Architecture',
                'reason': f"Better architectural quality ({diff:.0f} points higher)",
                'details': f"Fewer SOLID violations: {len(best_metrics['architecture']['solid_principles'].get('violations', []))} vs {len(worst_metrics['architecture']['solid_principles'].get('violations', []))}"
            })
            if worst_metrics['architecture']['solid_principles'].get('violations'):
                recommendations['improvements_for_others'].append({
                    'pr': worst_pr['pr_number'],
                    'category': 'Architecture',
                    'suggestion': f"Fix architectural violations: {', '.join(worst_metrics['architecture']['solid_principles']['violations'])}"
                })
        
        # Reusability comparison
        best_reuse = best_metrics['patterns']['reusability']['duplication_score']
        worst_reuse = worst_metrics['patterns']['reusability']['duplication_score']
        if best_reuse > worst_reuse:
            diff = best_reuse - worst_reuse
            recommendations['reasons_best_is_better'].append({
                'category': 'Reusability',
                'reason': f"Less code duplication ({diff:.1f} points higher)",
                'details': f"Duplication score: {best_reuse}% vs {worst_reuse}%"
            })
        
        return recommendations
    
    def _detailed_breakdown(self, analyses: Dict[str, Dict]) -> Dict[str, Any]:
        """Detailed breakdown of differences"""
        breakdown = {
            'files_comparison': self._compare_files(analyses),
            'risk_comparison': self._compare_risks(analyses),
            'pattern_comparison': self._compare_patterns(analyses),
            'soundscape_comparison': self._compare_soundscape_features(analyses)
        }
        
        return breakdown
    
    def _compare_files(self, analyses: Dict[str, Dict]) -> Dict[str, Any]:
        """Compare file-level metrics"""
        file_comparison = {}
        
        for pr_num, analysis in analyses.items():
            files = analysis['metrics'].get('files', {})
            high_risk_files = []
            
            for filepath, metrics in files.items():
                if metrics.get('risk_level') == 'high':
                    high_risk_files.append({
                        'path': filepath,
                        'risk_factors': len(metrics.get('risk_factors', [])),
                        'component': metrics.get('component', 'Unknown')
                    })
            
            file_comparison[pr_num] = {
                'total_files': len(files),
                'high_risk_files': high_risk_files,
                'high_risk_count': len(high_risk_files)
            }
        
        return file_comparison
    
    def _compare_risks(self, analyses: Dict[str, Dict]) -> Dict[str, Any]:
        """Compare risk levels across PRs"""
        risk_comparison = {}
        
        for pr_num, analysis in analyses.items():
            files = analysis['metrics'].get('files', {})
            
            risk_summary = {'high': 0, 'medium': 0, 'low': 0}
            total_risk_factors = 0
            
            for filepath, metrics in files.items():
                risk_level = metrics.get('risk_level', 'low')
                risk_summary[risk_level] += 1
                total_risk_factors += len(metrics.get('risk_factors', []))
            
            risk_comparison[pr_num] = {
                'risk_distribution': risk_summary,
                'total_risk_factors': total_risk_factors,
                'safety_score': 100 - min(total_risk_factors * 2, 100)
            }
        
        return risk_comparison
    
    def _compare_patterns(self, analyses: Dict[str, Dict]) -> Dict[str, Any]:
        """Compare design patterns usage"""
        pattern_comparison = {}
        
        for pr_num, analysis in analyses.items():
            files = analysis['metrics'].get('files', {})
            
            good_patterns = {}
            bad_patterns = {}
            
            for filepath, metrics in files.items():
                patterns = metrics.get('patterns', {})
                for pattern_name, count in patterns.get('good', {}).items():
                    good_patterns[pattern_name] = good_patterns.get(pattern_name, 0) + count
                for pattern_name, count in patterns.get('bad', {}).items():
                    bad_patterns[pattern_name] = bad_patterns.get(pattern_name, 0) + count
            
            pattern_comparison[pr_num] = {
                'good_patterns': good_patterns,
                'bad_patterns': bad_patterns,
                'pattern_score': len(good_patterns) * 10 - len(bad_patterns) * 5
            }
        
        return pattern_comparison
    
    def _compare_soundscape_features(self, analyses: Dict[str, Dict]) -> Dict[str, Any]:
        """Compare SoundScape-specific features"""
        soundscape_comparison = {}
        
        for pr_num, analysis in analyses.items():
            ss_metrics = analysis['metrics'].get('soundscape_specific', {})
            
            soundscape_comparison[pr_num] = {
                'affected_features': ss_metrics.get('affected_features', []),
                'audio_changes': ss_metrics.get('audio_session_changes', 0),
                'recording_changes': ss_metrics.get('recording_changes', 0),
                'paywall_changes': ss_metrics.get('paywall_changes', 0),
                'ui_changes': ss_metrics.get('ui_changes', 0),
                'concurrency_safety': ss_metrics.get('concurrency_patterns', 0)
            }
        
        return soundscape_comparison

def main():
    parser = argparse.ArgumentParser(description='Compare multiple PRs')
    parser.add_argument('--current-pr', required=True, help='Current PR number')
    parser.add_argument('--compare-prs', required=True, help='Comma-separated PR numbers to compare')
    parser.add_argument('--output-dir', required=True, help='Output directory')
    
    args = parser.parse_args()
    
    # Parse PR numbers
    pr_numbers = [args.current_pr] + [p.strip() for p in args.compare_prs.split(',')]
    pr_numbers = list(set(pr_numbers))  # Remove duplicates
    
    print(f"🔍 Comparing {len(pr_numbers)} PRs")
    
    # Create comparator
    output_dir = Path(args.output_dir)
    comparator = PRComparator(output_dir)
    
    # Perform comparison
    comparison = comparator.compare_prs(pr_numbers)
    
    if not comparison:
        print("❌ Comparison failed")
        return 1
    
    # Save comparison results
    output_file = output_dir / 'pr-comparison.json'
    with open(output_file, 'w') as f:
        json.dump(comparison, f, indent=2)
    
    print(f"✅ Comparison complete!")
    print(f"   Best PR: #{comparison['quality_ranking'][0]['pr_number']}")
    print(f"   Results saved to: {output_file}")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
