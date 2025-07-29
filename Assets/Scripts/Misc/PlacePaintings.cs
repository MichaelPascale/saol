using System.Collections.Generic;
using UnityEngine;

public class PlacePaintings : MonoBehaviour
{

    public GameObject prefab;
    public List<Texture> textures;
    void Start()
    {
        foreach (Texture t in textures) {
            int x = Random.Range(-15,15);
            int z = Random.Range(10,25);
            GameObject k = Instantiate(prefab, new Vector3(x, 2, z), Quaternion.identity);

            k.GetComponent<Renderer>().material.mainTexture = t;
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
