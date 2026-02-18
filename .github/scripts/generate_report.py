#!/usr/bin/env python3
"""
Report Generator for PR Quality Assessment

Generates comprehensive markdown reports from analysis data
"""

import os
import sys
import json
import argparse
from pathlib import Path
from typing import Dict, List, Any
from datetime import datetime

class ReportGenerator:
    """Generates markdown reports from analysis data"""
    
    GRADE_EMOJI = {
        'A': '🌟',
        'B': '✅',
        'C': '⚠️',
        'D': '❌',
        'F': '🚫'
    }
    
    RISK_EMOJI = {
        'low': '🟢',
        'medium': '🟡',
        'high': '🔴'
    }
    
    def __init__(self, analysis_dir: Path):
        self.analysis_dir = analysis_dir
        self.report_lines = []
        
    def add_line(self, line: str = ""):
        """Add a line to the report"""
        self.report_lines.append(line)
    
    def add_header(self, text: str, level: int = 1):
        """Add a markdown header"""
        self.add_line(f"{'#' * level} {text}")
        self.add_line()
    
    def add_table(self, headers: List[str], rows: List[List[str]]):
        """Add a markdown table"""
        # Header row
        self.add_line("| " + " | ".join(headers) + " |")
        # Separator
        self.add_line("| " + " | ".join(["---"] * len(headers)) + " |")
        # Data rows
        for row in rows:
            self.add_line("| " + " | ".join(str(cell) for cell in row) + " |")
        self.add_line()
    
    def generate_summary_section(self, analysis: Dict[str, Any], comparison: Dict[str, Any] = None):
        """Generate summary section"""
        self.add_header("📊 PR Quality Assessment Report", 1)
        
        pr_num = analysis.get('pr_number', 'Unknown')
        self.add_line(f"**PR Number:** #{pr_num}")
        self.add_line(f"**Analysis Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}")
        self.add_line()
        
        # Quality score card
        quality = analysis['metrics']['quality_score']
        grade = quality['grade']
        emoji = self.GRADE_EMOJI.get(grade, '❓')
        
        self.add_header("Overall Quality Score", 2)
        self.add_line(f"## {emoji} **Grade {grade}** - {quality['overall']:.2f}/100")
        self.add_line()
        
        # Score breakdown
        self.add_line("**Score Breakdown:**")
        for category, score in quality['breakdown'].items():
            bar_length = int(score / 5)
            bar = "█" * bar_length + "░" * (20 - bar_length)
            self.add_line(f"- **{category.title()}:** {score:.1f}/100 `{bar}`")
        self.add_line()
        
        # If comparison available, show ranking
        if comparison and 'quality_ranking' in comparison:
            rankings = comparison['quality_ranking']
            current_rank = next((r for r in rankings if r['pr_number'] == pr_num), None)
            if current_rank:
                self.add_line(f"**Rank:** {current_rank['rank']} out of {len(rankings)} PRs compared")
                self.add_line()
    
    def generate_metrics_section(self, analysis: Dict[str, Any]):
        """Generate detailed metrics section"""
        metrics = analysis['metrics']
        
        self.add_header("📈 Detailed Metrics", 2)
        
        # Basic metrics
        basic = metrics['basic']
        self.add_line("### Basic Statistics")
        self.add_table(
            ["Metric", "Value"],
            [
                ["Files Changed", str(basic['files_changed'])],
                ["Lines Added", f"+{basic['lines_added']}"],
                ["Lines Deleted", f"-{basic['lines_deleted']}"],
                ["Total Changes", str(basic['total_changes'])],
                ["Net Lines", f"{basic['net_lines']:+d}"]
            ]
        )
        
        # Complexity metrics
        complexity = metrics['complexity']
        self.add_line("### Complexity Analysis")
        self.add_table(
            ["Metric", "Value"],
            [
                ["Total Functions", str(complexity.get('total_functions', 0))],
                ["Average Complexity", f"{complexity.get('avg_complexity', 0):.2f}"],
                ["Max Complexity", str(complexity.get('max_complexity', 0))],
                ["High Complexity Functions", str(len(complexity.get('high_complexity_functions', [])))]
            ]
        )
        
        # Show high complexity functions if any
        high_cc = complexity.get('high_complexity_functions', [])
        if high_cc:
            self.add_line("**⚠️ High Complexity Functions (CC > 10):**")
            for func in high_cc[:10]:  # Limit to top 10
                self.add_line(f"- `{func['file']}`: `{func['function']}` (CC: {func['complexity']})")
            if len(high_cc) > 10:
                self.add_line(f"- *...and {len(high_cc) - 10} more*")
            self.add_line()
        
        # Distribution
        dist = complexity.get('complexity_distribution', {})
        if dist:
            self.add_line("**Complexity Distribution:**")
            total = sum(dist.values())
            if total > 0:
                for level, count in dist.items():
                    pct = (count / total) * 100
                    self.add_line(f"- {level.title()}: {count} ({pct:.1f}%)")
            self.add_line()
        
        # Architecture metrics
        arch = metrics['architecture']
        self.add_line("### Architecture Quality")
        self.add_table(
            ["Metric", "Score"],
            [
                ["Overall Architecture", f"{arch['architecture_score']}/100"],
                ["SOLID Principles", f"{arch['solid_principles']['score']}/100"],
                ["Separation of Concerns", f"{arch['separation_of_concerns']['score']}/100"],
                ["Violations Found", str(len(arch['solid_principles'].get('violations', [])))]
            ]
        )
        
        violations = arch['solid_principles'].get('violations', [])
        if violations:
            self.add_line("**⚠️ Architecture Violations:**")
            for violation in violations:
                self.add_line(f"- {violation}")
            self.add_line()
        
        # Testing metrics
        testing = metrics['testing']
        self.add_line("### Test Coverage")
        
        quality_emoji = {
            'excellent': '🌟',
            'good': '✅',
            'moderate': '⚠️',
            'poor': '❌',
            'unknown': '❓'
        }
        test_emoji = quality_emoji.get(testing['test_quality'], '❓')
        
        self.add_table(
            ["Metric", "Value"],
            [
                ["Code Files Changed", str(testing['code_files_changed'])],
                ["Test Files Changed", str(testing['test_files_changed'])],
                ["Code Lines Added", str(testing['code_lines_added'])],
                ["Test Lines Added", str(testing['test_lines_added'])],
                ["Test/Code Ratio", f"{testing['test_to_code_ratio']:.2f}"],
                ["Coverage Score", f"{testing['coverage_score']}/100"],
                ["Test Quality", f"{test_emoji} {testing['test_quality'].title()}"]
            ]
        )
        
        untested = testing.get('untested_components', [])
        if untested:
            self.add_line("**⚠️ Components Without Tests:**")
            for component in untested[:15]:  # Limit
                self.add_line(f"- `{component}`")
            if len(untested) > 15:
                self.add_line(f"- *...and {len(untested) - 15} more*")
            self.add_line()
        
        # Code reusability
        reusability = metrics['patterns'].get('reusability', {})
        if reusability:
            self.add_line("### Code Reusability")
            self.add_table(
                ["Metric", "Value"],
                [
                    ["Duplication Score", f"{reusability['duplication_score']:.2f}%"],
                    ["Lines Analyzed", str(reusability['total_lines_analyzed'])],
                    ["Duplicate Lines", str(reusability['duplicate_lines'])]
                ]
            )
            
            top_dupes = reusability.get('top_duplicates', [])
            if top_dupes:
                self.add_line("**Top Duplicated Code Patterns:**")
                for i, dupe in enumerate(top_dupes[:5], 1):
                    self.add_line(f"{i}. Found {dupe['count']} times: `{dupe['line'][:80]}...`")
                    self.add_line(f"   - Files: {', '.join(dupe['files'][:3])}")
                self.add_line()
    
    def generate_file_analysis_section(self, analysis: Dict[str, Any]):
        """Generate file-by-file analysis"""
        files = analysis['metrics'].get('files', {})
        
        if not files:
            return
        
        self.add_header("📁 File-by-File Analysis", 2)
        
        # Group by component
        by_component = {}
        for filepath, file_metrics in files.items():
            component = file_metrics.get('component', 'Other')
            if component not in by_component:
                by_component[component] = []
            by_component[component].append((filepath, file_metrics))
        
        for component, file_list in sorted(by_component.items()):
            self.add_line(f"### {component}")
            
            table_rows = []
            for filepath, file_metrics in file_list:
                risk_level = file_metrics.get('risk_level', 'low')
                risk_emoji = self.RISK_EMOJI.get(risk_level, '⚪')
                
                filename = Path(filepath).name
                changes = f"+{file_metrics['added']} -{file_metrics['deleted']}"
                risk_count = len(file_metrics.get('risk_factors', []))
                
                table_rows.append([
                    f"`{filename}`",
                    changes,
                    f"{risk_emoji} {risk_level.title()}",
                    str(risk_count)
                ])
            
            self.add_table(
                ["File", "Changes", "Risk Level", "Risk Factors"],
                table_rows
            )
        
        # Show high-risk files in detail
        high_risk_files = [(fp, fm) for fp, fm in files.items() if fm.get('risk_level') == 'high']
        
        if high_risk_files:
            self.add_line("### 🔴 High-Risk Files Details")
            
            for filepath, file_metrics in high_risk_files[:10]:  # Limit to 10
                self.add_line(f"#### `{Path(filepath).name}`")
                self.add_line(f"**Path:** `{filepath}`")
                self.add_line(f"**Component:** {file_metrics.get('component', 'Unknown')}")
                self.add_line(f"**Changes:** +{file_metrics['added']} -{file_metrics['deleted']}")
                self.add_line()
                
                risk_factors = file_metrics.get('risk_factors', [])
                if risk_factors:
                    self.add_line("**Risk Factors:**")
                    for rf in risk_factors:
                        level_emoji = self.RISK_EMOJI.get(rf['level'], '⚪')
                        self.add_line(f"- {level_emoji} {rf['level'].upper()}: `{rf['pattern']}` ({rf['count']} occurrences)")
                    self.add_line()
                
                # Show patterns
                patterns = file_metrics.get('patterns', {})
                good = patterns.get('good', {})
                bad = patterns.get('bad', {})
                
                if good:
                    self.add_line("**✅ Good Patterns:**")
                    for pattern, count in good.items():
                        self.add_line(f"- {pattern}: {count}")
                    self.add_line()
                
                if bad:
                    self.add_line("**❌ Anti-Patterns:**")
                    for pattern, count in bad.items():
                        self.add_line(f"- {pattern}: {count}")
                    self.add_line()
    
    def generate_soundscape_section(self, analysis: Dict[str, Any]):
        """Generate SoundScape-specific analysis"""
        ss_metrics = analysis['metrics'].get('soundscape_specific', {})
        
        if not ss_metrics:
            return
        
        self.add_header("🎵 SoundScape-Specific Analysis", 2)
        
        affected = ss_metrics.get('affected_features', [])
        if affected:
            self.add_line("**Affected Features:**")
            for feature in affected:
                self.add_line(f"- {feature}")
            self.add_line()
        
        self.add_line("**Change Categories:**")
        self.add_table(
            ["Category", "Changes"],
            [
                ["Audio Session", str(ss_metrics.get('audio_session_changes', 0))],
                ["Recording Logic", str(ss_metrics.get('recording_changes', 0))],
                ["Paywall/Premium", str(ss_metrics.get('paywall_changes', 0))],
                ["UI Components", str(ss_metrics.get('ui_changes', 0))],
                ["Concurrency Patterns", str(ss_metrics.get('concurrency_patterns', 0))]
            ]
        )
        
        # Add specific warnings for critical areas
        if ss_metrics.get('audio_session_changes', 0) > 0:
            self.add_line("> ⚠️ **Audio session changes detected.** Ensure proper session configuration and interruption handling.")
            self.add_line()
        
        if ss_metrics.get('recording_changes', 0) > 0:
            self.add_line("> ⚠️ **Recording logic changes detected.** Verify sleep recording lifecycle and snore detection accuracy.")
            self.add_line()
    
    def generate_comparison_section(self, comparison: Dict[str, Any]):
        """Generate PR comparison section"""
        if not comparison or 'quality_ranking' not in comparison:
            return
        
        self.add_header("🔄 PR Comparison", 2)
        
        rankings = comparison['quality_ranking']
        
        # Rankings table
        self.add_line("### Quality Rankings")
        table_rows = []
        for rank in rankings:
            grade_emoji = self.GRADE_EMOJI.get(rank['grade'], '❓')
            table_rows.append([
                str(rank['rank']),
                f"#{rank['pr_number']}",
                f"{grade_emoji} {rank['grade']}",
                f"{rank['overall_score']:.2f}",
                str(rank['total_changes']),
                f"{rank['quality_per_line']:.4f}"
            ])
        
        self.add_table(
            ["Rank", "PR", "Grade", "Score", "Changes", "Quality/Line"],
            table_rows
        )
        
        # Recommendations
        if 'recommendations' in comparison:
            recs = comparison['recommendations']
            
            self.add_line("### 🎯 Recommendations")
            self.add_line(f"**Best PR:** #{recs['best_pr']} (Score: {recs['best_pr_score']:.2f})")
            self.add_line()
            
            reasons = recs.get('reasons_best_is_better', [])
            if reasons:
                self.add_line("**Why this PR is better:**")
                for reason in reasons:
                    self.add_line(f"- **{reason['category']}:** {reason['reason']}")
                    self.add_line(f"  - {reason['details']}")
                self.add_line()
            
            improvements = recs.get('improvements_for_others', [])
            if improvements:
                # Group by PR
                by_pr = {}
                for imp in improvements:
                    pr = imp['pr']
                    if pr not in by_pr:
                        by_pr[pr] = []
                    by_pr[pr].append(imp)
                
                for pr, imps in by_pr.items():
                    self.add_line(f"**Improvements for PR #{pr}:**")
                    for imp in imps:
                        self.add_line(f"- **{imp['category']}:** {imp['suggestion']}")
                    self.add_line()
        
        # Detailed comparison
        if 'detailed_breakdown' in comparison:
            breakdown = comparison['detailed_breakdown']
            
            # Risk comparison
            if 'risk_comparison' in breakdown:
                self.add_line("### Risk Assessment Comparison")
                risk_comp = breakdown['risk_comparison']
                
                table_rows = []
                for pr_num, risk_data in risk_comp.items():
                    dist = risk_data['risk_distribution']
                    table_rows.append([
                        f"#{pr_num}",
                        str(dist.get('high', 0)),
                        str(dist.get('medium', 0)),
                        str(dist.get('low', 0)),
                        str(risk_data['total_risk_factors']),
                        f"{risk_data['safety_score']}/100"
                    ])
                
                self.add_table(
                    ["PR", "High Risk", "Medium Risk", "Low Risk", "Total Factors", "Safety Score"],
                    table_rows
                )
    
    def generate_recommendations_section(self, analysis: Dict[str, Any]):
        """Generate recommendations"""
        self.add_header("💡 Recommendations", 2)
        
        quality_score = analysis['metrics']['quality_score']['overall']
        testing = analysis['metrics']['testing']
        complexity = analysis['metrics']['complexity']
        arch = analysis['metrics']['architecture']
        
        recommendations = []
        
        # Testing recommendations
        if testing['coverage_score'] < 70:
            recommendations.append({
                'priority': 'HIGH',
                'category': 'Testing',
                'recommendation': f"Increase test coverage. Current test-to-code ratio is {testing['test_to_code_ratio']}, aim for at least 0.3"
            })
        
        if testing.get('untested_components'):
            count = len(testing['untested_components'])
            recommendations.append({
                'priority': 'MEDIUM',
                'category': 'Testing',
                'recommendation': f"Add tests for {count} untested components"
            })
        
        # Complexity recommendations
        high_cc_count = len(complexity.get('high_complexity_functions', []))
        if high_cc_count > 0:
            recommendations.append({
                'priority': 'HIGH',
                'category': 'Complexity',
                'recommendation': f"Refactor {high_cc_count} high-complexity functions (CC > 10)"
            })
        
        if complexity.get('avg_complexity', 0) > 7:
            recommendations.append({
                'priority': 'MEDIUM',
                'category': 'Complexity',
                'recommendation': f"Reduce average complexity from {complexity['avg_complexity']:.2f} to below 7"
            })
        
        # Architecture recommendations
        if arch['solid_principles'].get('violations'):
            recommendations.append({
                'priority': 'HIGH',
                'category': 'Architecture',
                'recommendation': f"Fix {len(arch['solid_principles']['violations'])} architectural violations"
            })
        
        # Display recommendations
        if recommendations:
            # Sort by priority
            priority_order = {'HIGH': 0, 'MEDIUM': 1, 'LOW': 2}
            recommendations.sort(key=lambda x: priority_order.get(x['priority'], 3))
            
            for rec in recommendations:
                emoji = '🔴' if rec['priority'] == 'HIGH' else '🟡' if rec['priority'] == 'MEDIUM' else '🟢'
                self.add_line(f"{emoji} **{rec['priority']} - {rec['category']}**")
                self.add_line(f"   {rec['recommendation']}")
                self.add_line()
        else:
            self.add_line("✅ No major recommendations. This PR meets quality standards!")
            self.add_line()
        
        # Production readiness
        self.add_line("### 🚀 Production Readiness")
        
        safety_checks = []
        if testing['coverage_score'] >= 70:
            safety_checks.append("✅ Good test coverage")
        else:
            safety_checks.append("❌ Insufficient test coverage")
        
        if complexity.get('avg_complexity', 0) < 7:
            safety_checks.append("✅ Low complexity")
        else:
            safety_checks.append("⚠️ Higher than ideal complexity")
        
        if arch['architecture_score'] >= 80:
            safety_checks.append("✅ Good architecture")
        else:
            safety_checks.append("⚠️ Architecture needs improvement")
        
        files = analysis['metrics'].get('files', {})
        high_risk_count = sum(1 for f in files.values() if f.get('risk_level') == 'high')
        if high_risk_count == 0:
            safety_checks.append("✅ No high-risk files")
        else:
            safety_checks.append(f"⚠️ {high_risk_count} high-risk files")
        
        for check in safety_checks:
            self.add_line(f"- {check}")
        self.add_line()
        
        # Overall verdict
        if quality_score >= 80:
            self.add_line("> ✅ **RECOMMENDED FOR MERGE** - This PR meets high quality standards")
        elif quality_score >= 70:
            self.add_line("> ⚠️ **MERGE WITH CAUTION** - Address recommendations before production")
        else:
            self.add_line("> ❌ **NOT RECOMMENDED** - Significant improvements needed before merge")
        self.add_line()
    
    def generate(self, output_file: Path):
        """Generate the report"""
        # Load analysis data
        analysis_files = list(self.analysis_dir.glob('pr-*-analysis.json'))
        
        if not analysis_files:
            print("❌ No analysis files found")
            return False
        
        # Load primary analysis
        primary_analysis_file = analysis_files[0]
        with open(primary_analysis_file, 'r') as f:
            analysis = json.load(f)
        
        # Load comparison if available
        comparison_file = self.analysis_dir / 'pr-comparison.json'
        comparison = None
        if comparison_file.exists():
            with open(comparison_file, 'r') as f:
                comparison = json.load(f)
        
        # Generate report sections
        self.generate_summary_section(analysis, comparison)
        self.generate_metrics_section(analysis)
        self.generate_file_analysis_section(analysis)
        self.generate_soundscape_section(analysis)
        
        if comparison:
            self.generate_comparison_section(comparison)
        
        self.generate_recommendations_section(analysis)
        
        # Add footer
        self.add_line("---")
        self.add_line("*Generated by SoundScape PR Quality Assessment*")
        self.add_line(f"*Analysis Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}*")
        
        # Write report
        with open(output_file, 'w') as f:
            f.write('\n'.join(self.report_lines))
        
        return True

def main():
    parser = argparse.ArgumentParser(description='Generate PR quality report')
    parser.add_argument('--analysis-dir', required=True, help='Directory with analysis results')
    parser.add_argument('--output-file', required=True, help='Output markdown file')
    
    args = parser.parse_args()
    
    analysis_dir = Path(args.analysis_dir)
    output_file = Path(args.output_file)
    
    print(f"📝 Generating report...")
    
    generator = ReportGenerator(analysis_dir)
    
    if generator.generate(output_file):
        print(f"✅ Report generated: {output_file}")
        return 0
    else:
        print("❌ Report generation failed")
        return 1

if __name__ == '__main__':
    sys.exit(main())
