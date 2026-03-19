#!/usr/bin/env python
from __future__ import print_function

"""
Script to inspect a ROOT file (e.g., muon_reco.root) and print:
- Number of events
- Number of branches
- Branch names
- Leaf information for each branch
"""

import sys
import os.path as osp
import argparse

try:
    import ROOT
except ImportError:
    print('ERROR: ROOT could not be imported')
    sys.exit(1)


def print_tree_info(tree, tree_name, directory=''):
    """Print detailed information about a TTree."""
    indent = '  ' if directory else ''
    
    # Get number of events (entries)
    n_entries = tree.GetEntries()
    
    # Get branches
    listofbranches = tree.GetListOfBranches()
    n_branches = listofbranches.GetEntries()
    
    # Print header
    print('\n' + '='*80)
    if directory:
        print(f'{indent}TDirectory: {directory}')
    print(f'{indent}TTree: {tree_name}')
    print('='*80)
    
    # Print summary
    print(f'\n{indent}Number of events (entries): {n_entries}')
    print(f'{indent}Number of branches: {n_branches}')
    
    # Print branches and their leaves
    print(f'\n{indent}Branches and Leaves:')
    print(f'{indent}{"-"*76}')
    
    for i_branch in range(n_branches):
        branch = listofbranches[i_branch]
        branch_name = branch.GetName()
        
        # Get leaves for this branch
        listofleaves = branch.GetListOfLeaves()
        n_leaves = listofleaves.GetEntries()
        
        print(f'\n{indent}Branch {i_branch+1}/{n_branches}: {branch_name}')
        
        if n_leaves > 0:
            print(f'{indent}  Leaves ({n_leaves}):')
            for i_leaf in range(n_leaves):
                leaf = listofleaves[i_leaf]
                leaf_name = leaf.GetName()
                leaf_type = leaf.GetTypeName()
                leaf_title = leaf.GetTitle()
                print(f'{indent}    - {leaf_name} (Type: {leaf_type}, Title: {leaf_title})')
        else:
            print(f'{indent}  No leaves')
    
    print('\n' + '='*80)


def iter_trees_recursively(node, directory=''):
    """Iterate through all TTrees in a ROOT file, including nested directories."""
    listofkeys = node.GetListOfKeys()
    n_keys = listofkeys.GetEntries()
    
    for i_key in range(n_keys):
        key = listofkeys[i_key]
        classname = key.GetClassName()
        
        # Recurse through TDirectories
        if classname == 'TDirectoryFile':
            dirname = key.GetName()
            lower_node = node.Get(dirname)
            new_directory = osp.join(directory, dirname) if directory else dirname
            print(f'\n\033[33mEntering TDirectory: {dirname}\033[0m')
            iter_trees_recursively(lower_node, directory=new_directory)
            continue
        elif classname != 'TTree':
            continue
        
        # Process TTree
        treename = key.GetName()
        tree = node.Get(treename)
        print_tree_info(tree, treename, directory)


def main():
    parser = argparse.ArgumentParser(
        description='Inspect ROOT files and print detailed information about TTrees, branches, and leaves'
    )
    parser.add_argument(
        'rootfile', 
        type=str, 
        help='Path to a ROOT file (e.g., muon_reco.root)'
    )
    parser.add_argument(
        '--tree',
        type=str,
        default=None,
        help='Only inspect a specific tree by name (optional)'
    )
    
    args = parser.parse_args()
    
    # Check if file exists
    if not osp.exists(args.rootfile):
        print(f'ERROR: File not found: {args.rootfile}')
        sys.exit(1)
    
    tfile = None
    try:
        # Open ROOT file
        print(f'\n\033[32mOpening ROOT file: {args.rootfile}\033[0m')
        tfile = ROOT.TFile.Open(args.rootfile)
        
        if not tfile or tfile.IsZombie():
            print(f'ERROR: Could not open ROOT file: {args.rootfile}')
            sys.exit(1)
        
        if args.tree:
            # Only process specific tree
            tree = tfile.Get(args.tree)
            if not tree:
                print(f'ERROR: Tree "{args.tree}" not found in file')
                sys.exit(1)
            print_tree_info(tree, args.tree)
        else:
            # Process all trees in file
            iter_trees_recursively(tfile)
        
        print('\n\033[32mDone!\033[0m\n')
        
    except Exception as e:
        print(f'\nERROR: {e}')
        sys.exit(1)
    finally:
        # Always try to close
        if tfile:
            try:
                tfile.Close()
            except:
                pass


if __name__ == '__main__':
    main()
