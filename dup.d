import std.stdio;
import std.string;
import std.conv;
import std.file;
import std.range;
import std.path;
import std.container;
import std.digest.md;

alias DList!(string) FileMatches;
alias char[16] Hash;

int main(string[] args)
{
    if(args.length != 2)
    {
        stderr.writefln("Needs 1 argument");
        return 1;
    }

    string rootAbs = args[1];
    writefln("root dir = %s", rootAbs);
    assert(exists(rootAbs));

    // maps from md5 hash to a list of all filename strings
    FileMatches[Hash] map;

    // hash files
    int fileCount = 0;
    foreach(string entry; dirEntries(rootAbs, SpanMode.breadth, false))
    {
        if(isFile(entry))
        {
            addFile(map, entry);
            fileCount++;
        }
    }
    writefln("Found %d files", fileCount);

    // make a list of all hashes that appear only once
    auto hashesToRemove = make!(DList!Hash);
    foreach(hash; map.byKey())
    {
        if(walkLength(map[hash][]) <= 1)
        {
            hashesToRemove.insert(hash);
        }
    }

    // remove any files whose hash only appears once
    foreach(hash; hashesToRemove)
    {
        map.remove(hash);
    }

    writefln("You have %d sets of duplicate files", map.length);
    if(map.length > 0)
    {
        interactive(map);
    }

    writefln("Done");
    return 0;
}


/**
 * Allows the user to search through sets of duplicate files
 */
void interactive(FileMatches[Hash] map)
{
    Hash[] allHashes = map.keys;
    while(true)
    {
        writeln();
        writef("Enter a number from 0 to %d, or exit: ", map.length-1);
        string input = chomp(readln());

        if(input == "exit")
        {
            break;
        }
        else // look up duplicates on a apecific index
        {
            int index;
            try
            {
                index = to!int(input);
            }
            catch(ConvException e)
            {
                stderr.writefln("Invalid Input.");
                continue;
            }

            // bounds checking
            if(index < 0 || index >= map.length)
            {
                stderr.writefln("Invalid Input.");
                continue;
            }

            auto set = map[allHashes[index]];
            writefln("The following files have the same content...");
            foreach(string fileName; set[])
            {
                writefln(fileName);
            }
        }
    }
}


/**
 * Adds a file to the maps list
 */
void addFile(ref FileMatches[Hash] map, const string newFile)
{
    Hash hash = md5(newFile);

    if((hash in map) == null)
    {
        map[hash] = make!(DList!(string));
    }

    map[hash].insert(newFile);
}


/**
 * Returns the md5 hash of the file 
 */
Hash md5(string filename)
{
    MD5 hasher;
    hasher.start();

    File file = File(filename, "r");
    foreach(ubyte[] buffer; file.byChunk(4))
    {
        hasher.put(buffer);
    }

    return cast(Hash) hasher.finish();
}

