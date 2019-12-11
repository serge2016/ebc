#!/usr/bin/python3

# Author: Nikita Kotlov, Sergey Mitrofanov.
# Last modification: 11.12.2019 19:25.

import argparse
import re
import string

parser = argparse.ArgumentParser(prog='mascot_pepts_to_svodn_v04.py', usage='%(prog)s inputFile outputFile', description='Script to create summary table with Mascot peptides',
                                 epilog="\xa9 avkitex 2016")
parser.add_argument('file', type=argparse.FileType('r'), help='File to consolidate')
parser.add_argument('output', type=argparse.FileType('w'), help='Output file')
parser.add_argument('-t', '--threshold', default=0, type=int, help='Score display threshols')
args = parser.parse_args()


header = args.file.readline().strip()[1:].split('\t')

uniqIds = set()
peptidesDict = {}

def stripPept(str):
    pattern = re.compile("^.\.[A-Z]+\..$")
    if pattern.match(str):
        return str[2:-2]
    else:
        return str

def desanitize(s):
    new_s = ''
    for i in s:
        if i in string.digits:
            new_s += i
    return new_s

for line in args.file:
    lineItems = line.strip().split('\t')
    if len(lineItems) < len(header):
        continue
    entry = dict(zip(header, lineItems))
    peptide = stripPept(entry['Peptide'])
    if peptide not in peptidesDict:
        peptidesDict[peptide] = {}
    if entry['FileID'] not in peptidesDict[peptide]:
        peptidesDict[peptide][entry['FileID']] = 0
    try:
        score = int(desanitize(entry['Score']))
    except Exception as e:
        score = 0
    peptidesDict[peptide][entry['FileID']] = max(peptidesDict[peptide][entry['FileID']], score)
    uniqIds.add(entry['FileID'])

args.file.close()

print('Unique peptides:', len(peptidesDict))
print('Unique ids:', len(uniqIds))

idslist = list(uniqIds)
idslist.sort()
print('Peptide\t{}\tAmount'.format('\t'.join(idslist)), file = args.output)
for peptide in sorted(peptidesDict.keys()):
    print(peptide, sep = '', end = '', file = args.output)
    count = 0
    for id in idslist:
        # score NA - not found
        out_score = None
        if id in peptidesDict[peptide]:
            # if found - redefine score
            out_score = peptidesDict[peptide][id]
        if out_score or out_score == 0:
            if out_score < args.threshold:
                out_score = '-'  # HERE output symbol replaces value if needed
            else:
                count += 1
        else:
            out_score = 'NA'
        print('\t', out_score, sep = '', end = '', file = args.output)
    print('\t', count, sep = '', file = args.output)

args.output.close()
