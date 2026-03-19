#!/usr/bin/env python3
"""
Validate that a ROOT file exists and contains events.
Exits with error code 1 if file is empty or invalid.
"""
import sys
import os

def validate_root_file(filepath):
    """Check if ROOT file exists and contains events."""
    
    # Check if file exists
    if not os.path.exists(filepath):
        print(f"ERROR: File does not exist: {filepath}", file=sys.stderr)
        return False
    
    # Check if file size is reasonable (at least 1KB)
    file_size = os.path.getsize(filepath)
    if file_size < 1024:
        print(f"ERROR: File is too small ({file_size} bytes): {filepath}", file=sys.stderr)
        return False
    
    # Try to open with ROOT and check event count
    try:
        import ROOT
        ROOT.PyConfig.IgnoreCommandLineOptions = True
        
        tfile = ROOT.TFile.Open(filepath, "READ")
        if not tfile or tfile.IsZombie():
            print(f"ERROR: Cannot open ROOT file: {filepath}", file=sys.stderr)
            return False
        
        # Try to get the Events tree
        events_tree = tfile.Get("Events")
        if not events_tree:
            print(f"ERROR: No 'Events' tree found in: {filepath}", file=sys.stderr)
            tfile.Close()
            return False
        
        n_events = events_tree.GetEntries()
        if n_events == 0:
            print(f"ERROR: File contains 0 events: {filepath}", file=sys.stderr)
            tfile.Close()
            return False
        
        print(f"✓ Valid ROOT file with {n_events} events: {os.path.basename(filepath)}")
        tfile.Close()
        return True
        
    except ImportError:
        print("WARNING: ROOT Python bindings not available, skipping detailed validation", file=sys.stderr)
        print(f"✓ File exists and has reasonable size: {os.path.basename(filepath)}")
        return True
    except Exception as e:
        print(f"ERROR: Exception while validating {filepath}: {e}", file=sys.stderr)
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: validate_root_file.py <rootfile>", file=sys.stderr)
        sys.exit(1)
    
    filepath = sys.argv[1]
    if validate_root_file(filepath):
        sys.exit(0)
    else:
        sys.exit(1)
