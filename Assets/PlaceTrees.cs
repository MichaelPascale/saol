using System.Collections.Generic;
using UnityEngine;

public class PlaceTrees : MonoBehaviour
{
    public List<GameObject> trees;
    public int n;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        for (int i = 0; i < n; i++) {
            float x = Random.Range(-45f,45f);
            float z = Random.Range(40f,45f);
            int t = Random.Range(0, trees.Count);
            GameObject k = Instantiate(trees[t], new Vector3(x, 0, z), Quaternion.Euler( 0, Random.Range( 0, 360 ), 0 ));
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
