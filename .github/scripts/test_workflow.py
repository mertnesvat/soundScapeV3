#!/usr/bin/env python3
"""
Test script to validate PR analysis workflow

This script creates mock data and tests the analysis pipeline
"""

import os
import sys
import json
import tempfile
import subprocess
from pathlib import Path

def create_test_environment():
    """Create a test environment with sample files"""
    test_dir = Path(tempfile.mkdtemp(prefix='pr_analysis_test_'))
    
    # Create sample Swift files with different quality levels
    
    # Good quality file
    good_file = test_dir / 'GoodExample.swift'
    good_file.write_text('''
import Foundation

@MainActor
@Observable
class AudioService {
    private let audioEngine: AudioEngineProtocol
    
    init(audioEngine: AudioEngineProtocol) {
        self.audioEngine = audioEngine
    }
    
    func playSound(named name: String) async throws {
        do {
            try await audioEngine.play(sound: name)
        } catch {
            throw AudioError.playbackFailed(error)
        }
    }
}

enum AudioError: Error {
    case playbackFailed(Error)
}
''')
    
    # Poor quality file with issues
    poor_file = test_dir / 'PoorExample.swift'
    poor_file.write_text('''
import Foundation
import AVFoundation

class BadAudioManager {
    var recorder: AVAudioRecorder!
    static var shared = BadAudioManager()
    
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(.record)
        try! session.setActive(true)
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        recorder = try! AVAudioRecorder(url: url, settings: [:])
        recorder!.record()
    }
    
    func complexFunction(data: [String]) -> String {
        var result = ""
        for item in data {
            if item.count > 5 {
                if item.contains("test") {
                    if item.hasPrefix("a") {
                        if item.hasSuffix("z") {
                            result += item
                        } else {
                            result += item.uppercased()
                        }
                    } else {
                        result += item.lowercased()
                    }
                } else {
                    result += item
                }
            }
        }
        return result
    }
}
''')
    
    # Test file
    test_file = test_dir / 'AudioServiceTests.swift'
    test_file.write_text('''
import XCTest
@testable import SoundScape

class AudioServiceTests: XCTestCase {
    func testPlaySound() async throws {
        let mockEngine = MockAudioEngine()
        let service = AudioService(audioEngine: mockEngine)
        
        try await service.playSound(named: "test")
        
        XCTAssertTrue(mockEngine.didPlay)
    }
}
''')
    
    return test_dir

def test_analysis_script():
    """Test the analyze_pr.py script"""
    print("🧪 Testing analysis script...")
    
    # Get repository root
    repo_root = Path(__file__).parent.parent.parent
    scripts_dir = repo_root / '.github' / 'scripts'
    
    # Create test environment
    test_dir = create_test_environment()
    output_dir = test_dir / 'results'
    output_dir.mkdir()
    
    # Copy test files to a git-tracked location
    os.chdir(repo_root)
    
    # Run analysis (will fail without git setup, but we can test imports)
    analyze_script = scripts_dir / 'analyze_pr.py'
    
    if analyze_script.exists():
        # Test that the script can be imported
        sys.path.insert(0, str(scripts_dir))
        
        try:
            # Test imports
            import analyze_pr
            print("✅ analyze_pr.py imports successfully")
            
            # Test CodeAnalyzer class
            analyzer = analyze_pr.CodeAnalyzer()
            print("✅ CodeAnalyzer instantiated successfully")
            
            # Test component identification
            component = analyzer.identify_component('Sources/Data/Services/AudioEngine.swift')
            assert component == 'AudioEngine', f"Expected 'AudioEngine', got '{component}'"
            print(f"✅ Component identification works: {component}")
            
        except Exception as e:
            print(f"❌ Error testing analyze_pr: {e}")
            return False
    else:
        print(f"❌ analyze_pr.py not found at {analyze_script}")
        return False
    
    return True

def test_comparison_script():
    """Test the compare_prs.py script"""
    print("\n🧪 Testing comparison script...")
    
    repo_root = Path(__file__).parent.parent.parent
    scripts_dir = repo_root / '.github' / 'scripts'
    compare_script = scripts_dir / 'compare_prs.py'
    
    if compare_script.exists():
        sys.path.insert(0, str(scripts_dir))
        
        try:
            import compare_prs
            print("✅ compare_prs.py imports successfully")
            
            # Test PRComparator class
            output_dir = Path(tempfile.mkdtemp())
            comparator = compare_prs.PRComparator(output_dir)
            print("✅ PRComparator instantiated successfully")
            
        except Exception as e:
            print(f"❌ Error testing compare_prs: {e}")
            return False
    else:
        print(f"❌ compare_prs.py not found at {compare_script}")
        return False
    
    return True

def test_report_generator():
    """Test the generate_report.py script"""
    print("\n🧪 Testing report generator...")
    
    repo_root = Path(__file__).parent.parent.parent
    scripts_dir = repo_root / '.github' / 'scripts'
    report_script = scripts_dir / 'generate_report.py'
    
    if report_script.exists():
        sys.path.insert(0, str(scripts_dir))
        
        try:
            import generate_report
            print("✅ generate_report.py imports successfully")
            
            # Test ReportGenerator class
            output_dir = Path(tempfile.mkdtemp())
            generator = generate_report.ReportGenerator(output_dir)
            print("✅ ReportGenerator instantiated successfully")
            
            # Test report building methods
            generator.add_header("Test Header", 1)
            generator.add_line("Test line")
            generator.add_table(["Col1", "Col2"], [["A", "B"], ["C", "D"]])
            
            assert len(generator.report_lines) > 0, "Report lines should not be empty"
            print("✅ Report building methods work")
            
        except Exception as e:
            print(f"❌ Error testing generate_report: {e}")
            return False
    else:
        print(f"❌ generate_report.py not found at {report_script}")
        return False
    
    return True

def test_threshold_checker():
    """Test the check_quality_thresholds.py script"""
    print("\n🧪 Testing threshold checker...")
    
    repo_root = Path(__file__).parent.parent.parent
    scripts_dir = repo_root / '.github' / 'scripts'
    threshold_script = scripts_dir / 'check_quality_thresholds.py'
    
    if threshold_script.exists():
        sys.path.insert(0, str(scripts_dir))
        
        try:
            import check_quality_thresholds
            print("✅ check_quality_thresholds.py imports successfully")
            
            # Test QualityChecker class
            output_dir = Path(tempfile.mkdtemp())
            checker = check_quality_thresholds.QualityChecker(output_dir, fail_on_regression=False)
            print("✅ QualityChecker instantiated successfully")
            
            # Verify thresholds are defined
            assert hasattr(checker, 'THRESHOLDS'), "THRESHOLDS should be defined"
            assert hasattr(checker, 'WARNING_THRESHOLDS'), "WARNING_THRESHOLDS should be defined"
            print("✅ Thresholds are properly defined")
            
        except Exception as e:
            print(f"❌ Error testing check_quality_thresholds: {e}")
            return False
    else:
        print(f"❌ check_quality_thresholds.py not found at {threshold_script}")
        return False
    
    return True

def validate_workflow_syntax():
    """Validate workflow YAML syntax"""
    print("\n🧪 Validating workflow YAML...")
    
    repo_root = Path(__file__).parent.parent.parent
    workflow_file = repo_root / '.github' / 'workflows' / 'pr-quality-assessment.yml'
    
    if not workflow_file.exists():
        print(f"❌ Workflow file not found at {workflow_file}")
        return False
    
    try:
        import yaml
        with open(workflow_file, 'r') as f:
            workflow_data = yaml.safe_load(f)
        
        # Check required sections
        assert 'name' in workflow_data, "Workflow must have a name"
        # Note: 'on' key is parsed as True by PyYAML (YAML reserved word)
        assert (True in workflow_data or 'on' in workflow_data), "Workflow must have triggers"
        assert 'jobs' in workflow_data, "Workflow must have jobs"
        
        print("✅ Workflow YAML is valid")
        print(f"   Name: {workflow_data['name']}")
        print(f"   Jobs: {', '.join(workflow_data['jobs'].keys())}")
        
        return True
        
    except ImportError:
        print("⚠️  PyYAML not installed, skipping YAML validation")
        print("   Install with: pip install pyyaml")
        # Don't fail the test for missing optional dependency
        return True
    except Exception as e:
        print(f"❌ Error validating workflow YAML: {e}")
        return False

def main():
    """Run all tests"""
    print("="*60)
    print("PR Quality Assessment Workflow - Test Suite")
    print("="*60)
    
    tests = [
        ("Workflow YAML Validation", validate_workflow_syntax),
        ("Analysis Script", test_analysis_script),
        ("Comparison Script", test_comparison_script),
        ("Report Generator", test_report_generator),
        ("Threshold Checker", test_threshold_checker),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} failed with exception: {e}")
            results.append((test_name, False))
    
    # Print summary
    print("\n" + "="*60)
    print("Test Summary")
    print("="*60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status}: {test_name}")
    
    print("="*60)
    print(f"Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed!")
        return 0
    else:
        print(f"❌ {total - passed} test(s) failed")
        return 1

if __name__ == '__main__':
    sys.exit(main())
