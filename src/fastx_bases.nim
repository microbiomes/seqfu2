
import readfq
import strformat
import tables, strutils
from os import fileExists
import docopt
import ./seqfu_utils

proc toString(c: CountTableRef[char], raw: bool, t: bool): string =
  var
    bases = 0
    normal = 0
    bases_array = newSeq[string]()
  for k, v in c:
    bases += v

  let
    display_total_bases = if t:  ($bases).insertSep(',')
                          else: $bases

  
  for base in @['A', 'C', 'G', 'T', 'N']:
      let
        count = if base in c: c[base]
                else: 0
      normal += count
      if raw:
        if t:
          bases_array.add($( ($count).insertSep(',') ))
        else:
          bases_array.add($count)
      else:
        bases_array.add(fmt"{float(100 * c['A'] / bases):.2f}")
  let 
    other = bases - normal
  if raw:
    if t:
      bases_array.add($( ($other).insertSep(',') ))
    else:
      bases_array.add($other)
  else:
    bases_array.add(fmt"{float(100 * other / bases):.2f}")
  result = fmt"{display_total_bases}{'\t'}{bases_array[0]}{'\t'}{bases_array[1]}{'\t'}{bases_array[2]}{'\t'}{bases_array[3]}{'\t'}{bases_array[4]}{'\t'}{bases_array[5]}"
    
    

  return

proc fastx_bases(argv: var seq[string]): int =
    let args = docopt("""
Usage: bases [options] [<inputfile> ...]

Print the DNA bases in the input files

Options:
  -c, --raw-counts       Print counts and not ratios
  -t, --thousands        Print thousands separator
  -a, --abspath          Print absolute path 
  -b, --basename         Print the basename of the file
  -H, --header           Print header
  -v, --verbose          Verbose output
  --debug                Debug output
  --help                 Show this help
  """, version=version(), argv=argv)

    verbose       = bool(args["--verbose"])
    var
      files       : seq[string]  

    let
      raw_counts    = bool(args["--raw-counts"])
      thousands     = bool(args["--thousands"])
      basename      = bool(args["--basename"])
      abspath       = bool(args["--abspath"])
    
    if bool(args["--debug"]):
      stderr.writeLine args
    if abspath and basename:
      echo "Error: --abspath and --basename are mutually exclusive"
      quit(1)
    if args["<inputfile>"].len() == 0:
      if getEnv("SEQFU_QUIET") == "":
        stderr.writeLine("[seqfu bases] Waiting for STDIN... [Ctrl-C to quit, type with --help for info].")
      files.add("-")
    else:
      for file in args["<inputfile>"]:
        files.add(file)
    
    
    if bool(args["--header"]):
      echo "#Filename\tTotal\tA\tC\tG\tT\tN\tOther"
    for filename in files:
      if not fileExists(filename) and filename != "-":
        stderr.writeLine("Skipping ", filename, ": not found")
        continue
      else:
        echoVerbose(filename, verbose)


      var 
        total_bases  = 0
        total_seqs   = 0
        counts       = newCountTable("")
      
      
      for record in readfq(filename):
        total_seqs += 1
        total_bases += len(record.sequence)
        
        for base in record.sequence:
          counts.inc(base.toUpperAscii())
      
      
      let displayname = if not basename and not abspath: filename
                        elif basename: extractFilename(filename) 
                        else: absolutePath(filename)
      echo display_name, "\t", counts.toString(raw_counts, thousands)