using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class CellularAutomatum : MonoBehaviour
{

    public RenderTexture automatum;
    public Texture3D texture;

    public int width = 32;
    public int depth = 32;
    public int height = 32;

    public int initialNumCells = 10;

    public float m_generation = 0;
    public bool initialized = false;
    public bool generateNewGen = false;

    private void OnValidate()
    {
        initialized = false;
    }
    public void InitTexture()
    {
        automatum = new RenderTexture(width, height, 24, RenderTextureFormat.ARGB32);
        automatum.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
        automatum.enableRandomWrite = true;
        automatum.filterMode = FilterMode.Point;
        automatum.depth = 0;
        automatum.volumeDepth = depth;
        automatum.Create();

        initialized = true;
  
    }

    private void OnMouseDown()
    {
        m_generation++;
        generateNewGen = true;
        Debug.Log("New Gen");
    }

}


/*
public void CreateTexture3D()
{
    // Configure the texture
    int size = width;
    TextureFormat format = TextureFormat.RGBA32;
    TextureWrapMode wrapMode = TextureWrapMode.Clamp;

    texture = new Texture3D(size, size, size, format, false);
    texture.wrapMode = wrapMode;

    Color[] colors = new Color[size * size * size];

    // Populate the array so that the x, y, and z values of the texture will map to red, blue, and green colors
    for (int x = 0; x < size; x++)
    {
        for (int y = 0; y < size; y++)
        {
            for (int z = 0; z < size; z++)
            {
                //float value = Get3DNoise(x, y * size, z * size * size, .001f);
                Color c = new Color(1.0f, .5f, 1.0f, 0.0f);
                colors[x + (y * size) + (z * size * size)] = c;
            }
        }
    }

    texture.SetPixels(colors);
    texture.Apply();
    AssetDatabase.CreateAsset(texture, "Assets/TestTexture.asset");

}*/