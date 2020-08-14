# Pointwise V18.3R2 Journal file - Fri Aug 14 10:52:10 2020

package require PWI_Glyph 3.18.3

set pwFile [lindex $argv 0]
if { [string match "*.pw" $pwFile] } {
  puts "Opening Pointwise project file $pwFile"
} else {
  puts "ERROR: the first argument must be a Pointwise project file (ending in .pw)"
  exit
}

puts "loading $pwFile..."
pw::Application reset
pw::Application load "$pwFile"

set blocks [pw::Grid getAll -type pw::Block]

set count 1
puts "#####################################################################################"
puts "           Summary of blocks contained in $pwFile           "
puts "           Block status is indicated as follows:            "
puts "             a ^ indicates an unstructured block            "
puts "             a # indicates a structured block              "
puts "             a @ indicates an extruded block                "
puts "             a ! is an uninitialized unstructured block     "
puts "             a * is an initialized unstructured block       "
puts "#####################################################################################"
foreach block $blocks {
  set blockType ""
  if { [$block getType] eq "pw::BlockUnstructured" } {
    set blockType "^"
  } elseif { [$block getType] eq "pw::BlockStructured" } {
    set blockType "#"
  } elseif { [$block getType] eq "pw::BlockExtruded" } {
    set blockType "@"
  }

  set initialized "!"
  if { $blockType eq "^" && [$block getInteriorState] eq "Initialized" } { set initialized "*" }

  puts "$count: $block (name: [$block getName], point count: [$block getPointCount]) \[$initialized$blockType\]"
  incr count
}
puts "#####################################################################################"

set count 1
set nReleasedBlocks 0
foreach block $blocks {
  set blockType ""
  if { [$block getType] eq "pw::BlockUnstructured" && [$block getInteriorState] eq "Initialized" } {
    puts -nonewline "Release block $count? \[y/N\] "
    flush stdout
    gets stdin response

    # Validate user input
    set foo [string tolower $response]
    if { $foo eq "y" } {
      puts "Releasing [$block getName]..."

      set releaseMode [pw::Application begin UnstructuredSolver [list $block]]
        $releaseMode run Release
        $releaseMode end
      unset releaseMode

      incr nReleasedBlocks

    } elseif { $foo eq "n" } {
      puts "NOT releasing [$block getName]"
    } else {
      puts "ERROR: you entered $response but you must enter on of: y, Y, n, N"
    }

  } else {
    puts "Skipping block $count ([$block getName])"
  }

  incr count
}


if { $nReleasedBlocks > 0 } {
  puts -nonewline "$nReleasedBlocks block(s) have been released, do you want to save $pwFile?  \[y/N\] "
  flush stdout
  gets stdin response

  # Validate user input
  set foo [string tolower $response]
  if { $foo eq "y" } {
    puts "Saving $pwFile"
    pw::Application save $pwFile
  } else {
    puts "Not saving $pwFile"
  }
}

exit
