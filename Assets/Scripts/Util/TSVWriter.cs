// TableWriter.cs, Copyright (c) 2025, Michael Pascale.
// SPDX-License-Identifier: MIT

/* We could use a library for this, but for now it's nice to have the
 * flexibility to write out data and handle errors using our own class. 
 */

using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;
public class TableWriter<T>
{

    public readonly string[] headers;
    public readonly int ncol;
    public readonly Func<T, string> formatter;

    public readonly string delim;
    public readonly string newline;

    private List<string> data;

    // If the user specifies headers, the headers array determines the number of columns.
    public TableWriter(string[] headers, Func<T, string> formatter, string delim = "\t", string newline = "\n")
    {
        this.headers = headers;
        ncol = headers.Length;
        this.formatter = formatter;
        this.delim = delim;
        this.newline = newline;

        data = new() { string.Join(delim, headers) };
    }
    // Otherwise, there is no header row and the user must specify the number of columns.
    public TableWriter(int ncol, Func<T, string> formatter, string delim = "\t", string newline = "\n")
    {
        this.formatter = formatter;
        this.delim = delim;
        this.newline = newline;

        headers = null;
        data = new();
    }

    public TableWriter<T> append(T item)
    {
        data.Add(formatter(item));
        return this;
    }

    public TableWriter<T> append(List<T> items)
    {
        foreach (T item in items) append(item);
        return this;
    }

    public TableWriter<T> write(string filename)
    {
        File.AppendAllText(
            Path.Combine(Application.persistentDataPath, filename),
            string.Join(newline, data),
            Encoding.UTF8
        );

        return this;
    }
}


