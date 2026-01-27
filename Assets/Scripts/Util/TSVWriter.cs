// TableWriter.cs, Copyright (c) 2025, Michael Pascale.
// SPDX-License-Identifier: MIT

/* We could use a library for this, but for now it's nice to have the
 * flexibility to write out data and handle errors using our own class. 
 */

using System;
using System.IO.Compression;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;
using K4os.Compression.LZ4.Internal;
public class TableWriter<ITuple>
{

    public readonly string[] headers;
    public readonly int ncol;
    public readonly Func<ITuple, string> formatter;

    public readonly string delim;
    public readonly string newline;

    private List<string> data;

    // If the user specifies headers, the headers array determines the number of columns.
    public TableWriter(string[] headers, Func<ITuple, string> formatter, string delim = "\t", string newline = "\n")
    {
        this.headers = headers;
        ncol = headers.Length;
        this.formatter = formatter;
        this.delim = delim;
        this.newline = newline;

        data = new() { string.Join(delim, headers) };
    }
    // Otherwise, there is no header row and the user must specify the number of columns.
    public TableWriter(int ncol, Func<ITuple, string> formatter, string delim = "\t", string newline = "\n")
    {
        this.formatter = formatter;
        this.delim = delim;
        this.newline = newline;

        headers = null;
        data = new();
    }

    public TableWriter<ITuple> append(ITuple item)
    {
        data.Add(formatter(item));
        return this;
    }

    public TableWriter<ITuple> append(List<ITuple> items)
    {
        foreach (ITuple item in items) append(item);
        return this;
    }

    public string serialize()
    {
        return string.Join(newline, data);
    }

    public TableWriter<ITuple> write(string filename)
    {

        if (filename.EndsWith(".gz"))
        {
            using (FileStream stream = File.Create(Path.Combine(Application.persistentDataPath, filename)))
            using (GZipStream compressor = new GZipStream(stream, System.IO.Compression.CompressionLevel.Optimal))
            using (StreamWriter writer = new StreamWriter(compressor, Encoding.UTF8))
            {
                foreach (var line in data)
                    writer.WriteLine(line);
            }

            return this;
        }

        File.AppendAllText(
            Path.Combine(Application.persistentDataPath, filename),
            serialize(),
            Encoding.UTF8
        );

        return this;
    }
}


