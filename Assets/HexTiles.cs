using System;
using System.Collections.Generic;
using System.IO.Compression;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.InputSystem.Interactions;
using UnityEngine.UIElements;
using static System.Math;

public class HexTile3D
{
    public Vector3 location;
    public readonly GameObject gobj;

    public HexTile3D(string name, Vector3 where, uint walls=0x7F) {
        gobj = new GameObject(name);

        gobj.AddComponent<MeshFilter>();
        gobj.AddComponent<MeshRenderer>();
        gobj.AddComponent<MeshCollider>();

        // Create a mesh for the hexagonal floor.
        Mesh mesh = gobj.GetComponent<MeshFilter>().mesh;
        mesh.Clear();

        // Allocate a center and six points.
        Vector3[]
        vertices = new Vector3[7];

        Vector2[]
        uvs = new Vector2[7];

        // Define the vertices of the hexagon in clockwise fashion.
        // Unity assumes the front face of a mesh has clockwise triangle winding.
        vertices[0] = Vector3.zero;
        for (uint i = 0; i < 6; i++) vertices[i+1] = new Vector3((float)Cos(-i*PI/3), 0, (float)Sin(-i*PI/3));

        mesh.vertices = vertices;

        // A hexagon is six triangles, six triplets of vertices.
        int[]
        triangles = new int[18];
        for (int i = 0; i < 6; i++) {
            triangles[i*3] = 0;
            triangles[i*3+1] = i + 1;
            triangles[i*3+2] = i < 5 ? i + 2 : 1;
        }

        mesh.triangles = triangles;
    }
}


public class HexTiles : MonoBehaviour
{
    void Start()
    {
        HexTile3D h = new HexTile3D("test hex", Vector3.zero, 0x15);
        print(h.gobj.GetComponent<MeshFilter>().mesh.uv);
    }

    void Update()
    {

    }
}