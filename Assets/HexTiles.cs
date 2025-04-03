using System;
using System.Collections.Generic;
using System.IO.Compression;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEditor.Build;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.InputSystem.Interactions;
using UnityEngine.UIElements;
using static System.Math;

public class HexTile3D
{
    public string name;
    public Vector3 location;
    public readonly GameObject gobj;

    private const float HEIGHT = 1;
    private enum Directions { SouthEast, South, SouthWest, NorthWest, North, NorthEast };

    public HexTile3D(string name, Vector3 where, uint wflags = 0xFF, Material[] materials = null) {
        gobj = new GameObject(name);
        this.name = name;
        location = where;

        gobj.AddComponent<MeshFilter>();
        gobj.AddComponent<MeshRenderer>();
        gobj.AddComponent<MeshCollider>();

        {
            // Create a mesh for the hexagonal floor.
            Mesh mesh = gobj.GetComponent<MeshFilter>().mesh;
            mesh.Clear();

            // Allocate a center and six points.
            List<Vector3>
            vertices = new List<Vector3>();

            // Define the vertices of the hexagon in clockwise fashion.
            // Unity assumes the front face of a mesh has clockwise triangle winding.
            vertices.Add(Vector3.zero);
            for (uint i = 0; i < 6; i++) vertices.Add(new Vector3((float)Cos(-i*PI/3), 0, (float)Sin(-i*PI/3)));

            mesh.vertices = vertices.ToArray();

            // A hexagon is six triangles, six triplets of vertices.
            List<int>
            triangles = new List<int>();
            for (int i = 0; i < 6; i++) triangles.AddRange(new int[] {0, i + 1, i < 5 ? i + 2 : 1});

            mesh.triangles = triangles.ToArray();

            // Generate UVs. Will unwrap a circle through the middle of the texture.
            Vector2[] uvs = new Vector2[7];
            for (int i = 0; i < 6; i++) uvs[i] = new Vector2(vertices[i].x/2+.5f, vertices[i].z/2+.5f);
            mesh.uv = uvs;

            // Set the render material.
            if (materials != null && materials.Length > 0)
                gobj.GetComponent<MeshRenderer>().material = materials[0];
        }
    
        // If a ceiling is specified (seventh bit), then duplicate the floor.
        // if ((walls & 0x40) > 0) {
        //     for (uint i = 0; i < 6; i++) vertices.Add(new Vector3((float)Cos(i*PI/3), 1, (float)Sin(i*PI/3)));
        //     for (int i = 7; i < 13; i++) triangles.AddRange(new int[] {7, i + 1, i < 5 ? i + 2 : 8});
        // }

        // Add a wall on the far face of each triangle, according to the walls flag.
        // Six binary flags (two octal digits) set the clockwise wall presence:
        //     southeast, south, southwest, northwest, north, northeast
        {
            GameObject walls = new GameObject("walls");
            walls.AddComponent<MeshFilter>();
            walls.AddComponent<MeshRenderer>();
            walls.AddComponent<MeshCollider>();
            Mesh mesh = walls.GetComponent<MeshFilter>().mesh;
            mesh.Clear();

            List<Vector3>
            vertices = new List<Vector3>();

            List<int>
            triangles = new List<int>();

            int wcount = 0;
            for (int i = 0; i < 6; i++) {
                if ((wflags & 0x1u) > 0) {
                    
                    // Create Quads, starting from the bottom left corner of each.
                    vertices.AddRange(new Vector3[] {
                        new Vector3((float)Cos(-i*PI/3),     0,         (float)Sin(-i*PI/3)),
                        new Vector3((float)Cos(-i*PI/3),     HEIGHT,    (float)Sin(-i*PI/3)),
                        new Vector3((float)Cos(-(i+1)*PI/3), HEIGHT,    (float)Sin(-(i+1)*PI/3)),
                        new Vector3((float)Cos(-(i+1)*PI/3), 0,         (float)Sin(-(i+1)*PI/3)),
                    });

                    // Add triangles.
                    // Vertex indicies depend on how many walls have been created so far.
                    int o = (i-wcount)*4;
                    triangles.AddRange(new int[] {
                        o+0, o+1, o+2,
                        o+2, o+3, o+0
                    });

                    wcount++;
                }
                

                wflags = wflags >> 1;
            }

            mesh.vertices = vertices.ToArray();
            mesh.triangles = triangles.ToArray();
            walls.transform.parent = gobj.transform;
            
            if (materials != null && materials.Length > 0) {
                walls.GetComponent<MeshRenderer>().material = materials[materials.Length > 1 ? 1 : 0];
            }
        }

        gobj.transform.position = where;
    }
}


public class HexTiles : MonoBehaviour
{

    public Material mat_walls;
    public Material mat_floor;
    void Start()
    {
        Material[] materials = {mat_floor, mat_walls};
        HexTile3D h = new HexTile3D("test hex", Vector3.zero, 0x37, materials);
        new HexTile3D("northeast", new Vector3(1.5f, 0, (float)Sqrt(3)/2), 0x3A, materials);
        new HexTile3D("east", new Vector3(3, 0, 0), 0x1F, materials);


        new HexTile3D("other", new Vector3(6, 1, 6), 0xFF, materials);

        new HexTile3D("other", new Vector3(-6, 1, -6), 0x00, materials);

    }

    void Update()
    {

    }
}