# Quick Start Guide - PR Quality Assessment

## Setup (One-time)

The workflow is ready to use! No configuration needed. It will automatically run on all PRs.

## Usage

### Automatic Analysis (Default)

Every time you:
- Open a PR
- Push new commits to a PR
- Reopen a PR

The workflow automatically:
1. Analyzes code quality
2. Generates a comprehensive report
3. Posts the report as a PR comment
4. Uploads detailed artifacts

**No action required!**

### Manual PR Comparison

To compare multiple PRs:

1. **Go to GitHub Actions tab**
   - Navigate to your repository
   - Click "Actions" at the top

2. **Select the workflow**
   - Find "PR Quality Assessment" in the left sidebar
   - Click on it

3. **Run workflow**
   - Click "Run workflow" button (top right)
   - Enter PR numbers separated by commas
   - Example: `123,124,125`
   - Click "Run workflow"

4. **View results**
   - Wait for workflow to complete (~2-5 minutes)
   - Check the PR comment for summary
   - Download artifacts for detailed JSON/markdown reports

## Reading the Report

### Quick Glance

Look for these key indicators:

```markdown
## 🌟 **Grade A** - 92.50/100
```

- **Grade A (90-100)**: ✅ Ready to merge
- **Grade B (80-89)**: ✅ Good, minor improvements suggested  
- **Grade C (70-79)**: ⚠️ Address issues before merge
- **Grade D (60-69)**: ❌ Needs significant work
- **Grade F (0-59)**: ❌ Major refactoring required

### Key Metrics to Check

1. **Test Coverage** - Should be ≥ 70/100
2. **Complexity** - Should be < 7 average
3. **High-Risk Files** - Should be 0-3
4. **Architecture Score** - Should be ≥ 80/100

### Production Readiness

At the bottom of each report:

```markdown
> ✅ **RECOMMENDED FOR MERGE** - This PR meets high quality standards
```

or

```markdown
> ⚠️ **MERGE WITH CAUTION** - Address recommendations before production
```

or

```markdown
> ❌ **NOT RECOMMENDED** - Significant improvements needed
```

## Common Scenarios

### Scenario 1: Your PR Gets a Low Score

**Don't panic!** Follow these steps:

1. **Check Test Coverage**
   - Add tests for untested components
   - Aim for test-to-code ratio ≥ 0.3

2. **Fix High Complexity Functions**
   - Refactor functions with CC > 10
   - Break down complex logic into smaller functions

3. **Address High-Risk Files**
   - Fix force unwraps (!), force try (try!), force cast (as!)
   - Add proper error handling

4. **Fix Architecture Violations**
   - Ensure Domain layer doesn't depend on Data/UI layers
   - Use dependency injection

5. **Push Changes**
   - The workflow will automatically re-run
   - See updated scores

### Scenario 2: Comparing Two Feature PRs

You have two PRs implementing the same feature:

1. **Run comparison**
   - Actions → PR Quality Assessment → Run workflow
   - Enter both PR numbers: `123,124`

2. **Review comparison report**
   - Check quality rankings table
   - Read "Why this PR is better" section
   - Review improvements for lower-ranked PR

3. **Make decision**
   - Choose higher-ranked PR
   - Or improve lower-ranked PR based on recommendations

### Scenario 3: Pre-merge Checklist

Before merging any PR:

1. ✅ Overall score ≥ 80/100
2. ✅ Test coverage ≥ 70/100
3. ✅ No high-complexity functions (CC > 15)
4. ✅ Zero high-risk files (or justified exceptions)
5. ✅ Zero architecture violations
6. ✅ Production readiness: "RECOMMENDED FOR MERGE"

## Customization

### Adjust Quality Thresholds

Edit `.github/scripts/check_quality_thresholds.py`:

```python
THRESHOLDS = {
    'minimum_overall_score': 60,  # Change to 70 for stricter requirements
    'minimum_test_coverage_score': 50,  # Change to 70 for better coverage
    'maximum_avg_complexity': 15,  # Change to 10 for simpler code
    # ... etc
}
```

### Add Custom SoundScape Components

Edit `.github/scripts/analyze_pr.py`:

```python
SOUNDSCAPE_COMPONENTS = {
    'AudioEngine': ['AudioEngine.swift', 'BinauralBeatEngine.swift'],
    'Your Component': ['YourFile.swift', 'AnotherFile.swift'],
    # ... add more
}
```

### Fail Build on Poor Quality

Edit `.github/workflows/pr-quality-assessment.yml`:

Change:
```yaml
--fail-on-regression true
```

to:
```yaml
--fail-on-regression true
```

(It's already set to true by default)

## Troubleshooting

### Workflow Doesn't Run

**Check:**
- Workflow file is in `.github/workflows/` directory
- File is named `pr-quality-assessment.yml`
- GitHub Actions is enabled in repository settings

### Analysis Fails

**Common causes:**
- No Swift files changed in PR
- Git history not accessible
- Python dependencies not installed

**Solution:**
- Check workflow logs in Actions tab
- Ensure PR has actual code changes
- Verify workflow YAML is correct

### Report Not Posted to PR

**Check:**
- Workflow has `pull-requests: write` permission
- PR is not from a fork (forks have limited permissions)
- GitHub token is valid

### Comparison Fails

**Check:**
- All PR numbers exist and are accessible
- PRs have been analyzed (open/push triggered workflow)
- Analysis JSON files were generated

## Tips & Best Practices

### For Developers

1. **Run analysis early** - Don't wait until PR is huge
2. **Incremental improvements** - Fix issues as you code
3. **Write tests first** - Better test coverage scores
4. **Keep functions small** - Lower complexity scores
5. **Follow architecture** - Respect layer boundaries

### For Reviewers

1. **Check the grade** - A/B = quick review, C/D/F = thorough review
2. **Focus on high-risk files** - These need extra attention
3. **Validate recommendations** - Ensure they're addressed
4. **Use comparison** - Compare with similar PRs
5. **Trust the metrics** - Data-driven review decisions

### For Team Leads

1. **Set team standards** - Adjust thresholds to match
2. **Track trends** - Monitor quality over time
3. **Celebrate improvements** - Recognize high-quality PRs
4. **Address patterns** - If all PRs score low, provide training
5. **Enforce minimums** - Don't merge F-grade PRs

## Examples

See [EXAMPLE_REPORTS.md](./EXAMPLE_REPORTS.md) for sample reports showing:
- High-quality PR (Grade A)
- Needs-improvement PR (Grade C)
- PR comparison report

## Support

For issues or questions:
1. Check workflow logs in Actions tab
2. Review this documentation
3. Examine example reports
4. Check script comments for details

## Next Steps

1. ✅ Open your first PR
2. ✅ Wait for automatic analysis
3. ✅ Review the report
4. ✅ Address any issues
5. ✅ See improved scores!

Happy coding! 🚀
