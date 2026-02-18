# PR Quality Assessment Workflow

Comprehensive GitHub Actions workflow for deep PR quality analysis and comparison.

## Overview

This workflow provides detailed analysis of pull requests in the soundScapeV3 iOS app, including:

- **Advanced Metrics**: Cyclomatic complexity, architecture quality, code reusability, test coverage
- **Comparative Analysis**: Side-by-side comparison of multiple PRs
- **Swift/iOS Specific**: Audio handling, concurrency safety, memory management, SwiftUI patterns
- **Risk Assessment**: Identifies high-risk code areas
- **Detailed Reports**: Comprehensive markdown reports with recommendations

## Features

### 1. Automated PR Analysis

Every PR automatically receives:
- Overall quality score (0-100) with letter grade (A-F)
- Cyclomatic complexity analysis with function-level details
- Architecture quality assessment (SOLID principles, layer separation)
- Test coverage metrics and test-to-code ratio
- Code duplication detection
- Risk factor identification
- SoundScape-specific pattern analysis

### 2. Multi-PR Comparison

Compare multiple PRs side-by-side:
- Quality rankings
- Metric comparisons (complexity, testing, architecture)
- Recommendation engine showing which PR is better and why
- Safety score comparison

### 3. Detailed Reports

Generated reports include:
- 📊 Summary with overall score and grade
- 📈 Detailed metrics breakdown
- 📁 File-by-file analysis grouped by component
- 🎵 SoundScape-specific insights (Audio, Recording, Paywall, UI)
- 🔄 PR comparison tables (when comparing multiple PRs)
- 💡 Actionable recommendations
- 🚀 Production readiness assessment

### 4. Quality Thresholds

Automatic checks ensure:
- Minimum overall score: 60/100
- Minimum test coverage: 50/100
- Maximum average complexity: 15
- Minimum architecture score: 60/100
- Maximum high-risk files: 10
- Minimum duplication score: 70%

## Usage

### Automatic Analysis

The workflow runs automatically on every PR:
- Opens, synchronizes, or reopens trigger analysis
- Results posted as PR comment
- Analysis artifacts stored for 90 days

### Manual PR Comparison

To compare multiple PRs:

1. Go to Actions tab
2. Select "PR Quality Assessment" workflow
3. Click "Run workflow"
4. Enter PR numbers separated by commas (e.g., `123,124,125`)
5. Run workflow

The comparison report will be generated and available in artifacts.

## Workflow Components

### 1. Main Workflow (`.github/workflows/pr-quality-assessment.yml`)

Orchestrates the analysis process:
- Sets up Python environment
- Installs analysis tools (lizard, radon, SwiftLint)
- Runs analysis scripts
- Generates reports
- Posts results as PR comments
- Checks quality thresholds

### 2. Analysis Scripts

#### `analyze_pr.py`
Main analysis script that:
- Analyzes git diff and changed files
- Calculates cyclomatic complexity using lizard
- Evaluates architecture patterns
- Assesses test coverage
- Detects code duplication
- Identifies Swift/iOS patterns and anti-patterns
- Analyzes SoundScape-specific features

#### `compare_prs.py`
Comparison script that:
- Loads analysis results for multiple PRs
- Compares metrics side-by-side
- Ranks PRs by quality
- Generates recommendations
- Provides detailed breakdown of differences

#### `generate_report.py`
Report generator that:
- Creates comprehensive markdown reports
- Includes tables, metrics, and visualizations
- Adds emojis and formatting for readability
- Generates both single PR and comparison reports

#### `check_quality_thresholds.py`
Quality gate that:
- Validates PR against minimum thresholds
- Generates warnings for recommended improvements
- Can fail workflow on quality regressions
- Creates GitHub Actions annotations

## Metrics Explained

### Overall Quality Score

Weighted average of:
- **Complexity** (100 - avg_complexity * 5): Lower complexity is better
- **Architecture**: SOLID principles and layer separation
- **Testing**: Test coverage and test-to-code ratio
- **Reusability**: Code duplication score

### Grade Scale
- **A (90-100)**: Excellent quality, production-ready
- **B (80-89)**: Good quality, minor improvements suggested
- **C (70-79)**: Acceptable quality, some improvements needed
- **D (60-69)**: Below standard, significant improvements needed
- **F (0-59)**: Poor quality, major refactoring required

### Complexity Metrics
- **Low (CC ≤ 5)**: Simple, easy to maintain
- **Medium (CC 6-10)**: Moderate complexity
- **High (CC > 10)**: Complex, should be refactored

### Risk Levels
- **🔴 High**: Critical patterns (force unwrap, unsafe threading, audio session)
- **🟡 Medium**: Moderate concerns (state management, file I/O)
- **🟢 Low**: Minor issues (print statements, TODOs)

## SoundScape-Specific Analysis

### Audio/Media Handling
- AVAudioSession usage patterns
- AVAudioRecorder lifecycle management
- Audio interruption handling
- Session configuration safety

### Concurrency Safety
- @MainActor usage for UI updates
- async/await patterns
- Thread safety in audio code
- Dispatch queue usage

### Memory Management
- Weak self in closures
- Resource cleanup
- Delegate pattern safety
- Potential retain cycles

### UI/UX Quality
- SwiftUI best practices
- @Observable and @Environment usage
- State management patterns
- View composition

## Example Report

```markdown
# 📊 PR Quality Assessment Report

**PR Number:** #123
**Analysis Date:** 2024-01-15 10:30:00 UTC

## 🌟 **Grade A** - 92.50/100

**Score Breakdown:**
- **Complexity:** 95.0/100 `███████████████████░`
- **Architecture:** 90.0/100 `██████████████████░░`
- **Testing:** 90.0/100 `██████████████████░░`
- **Reusability:** 95.0/100 `███████████████████░`

### ✅ Good test coverage
### ✅ Low complexity
### ✅ Good architecture
### ✅ No high-risk files

> ✅ **RECOMMENDED FOR MERGE** - This PR meets high quality standards
```

## Configuration

### Adjust Thresholds

Edit `.github/scripts/check_quality_thresholds.py`:

```python
THRESHOLDS = {
    'minimum_overall_score': 60,
    'minimum_test_coverage_score': 50,
    'maximum_avg_complexity': 15,
    # ... add more
}
```

### Customize SoundScape Components

Edit `.github/scripts/analyze_pr.py`:

```python
SOUNDSCAPE_COMPONENTS = {
    'AudioEngine': ['AudioEngine.swift', 'BinauralBeatEngine.swift'],
    'Sleep Recording': ['SleepRecordingService.swift'],
    # ... add more components
}
```

## Artifacts

Each workflow run stores:
- `pr-{number}-analysis.json`: Raw analysis data
- `pr-comparison.json`: Comparison data (if comparing)
- `pr-quality-report.md`: Markdown report

Artifacts are retained for 90 days and can be downloaded from the Actions tab.

## Troubleshooting

### Analysis fails with "No changed files"
- Ensure PR has commits
- Check that base branch is accessible
- Verify git fetch depth is sufficient

### SwiftLint errors
- SwiftLint may not be available on GitHub Actions runners
- Consider installing via homebrew or providing binary

### Missing metrics in report
- Check that analysis completed successfully
- Verify changed files include .swift files
- Review workflow logs for errors

## Best Practices

1. **Regular Reviews**: Check reports for each PR before merging
2. **Trend Monitoring**: Compare current PR with historical data
3. **Team Standards**: Use threshold checks to enforce team standards
4. **Continuous Improvement**: Gradually increase thresholds as code quality improves

## Contributing

To improve the analysis:
1. Add new metrics in `analyze_pr.py`
2. Enhance comparison logic in `compare_prs.py`
3. Improve report formatting in `generate_report.py`
4. Adjust thresholds in `check_quality_thresholds.py`

## License

This workflow is part of the soundScapeV3 project.
