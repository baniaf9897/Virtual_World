using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
 public class WorldMgr : MonoBehaviour
{
 
    public ComputeShader CA;
    CellularAutomatum m_CellularAutomatumManager;
    public bool trigger = false;

    float updateRateSec = 0.5f;
    float time = 0.0f;
    void Update()
    {
        time += Time.deltaTime;
        if(time > updateRateSec) {
            m_CellularAutomatumManager.m_generation++;
            m_CellularAutomatumManager.generateNewGen = true;
            time = 0.0f;
        };


        m_CellularAutomatumManager = transform.GetComponent<CellularAutomatum>();
        if (!m_CellularAutomatumManager.initialized || m_CellularAutomatumManager.generateNewGen)
        {
            UpdateTexture();
            m_CellularAutomatumManager.initialized = true;
            m_CellularAutomatumManager.generateNewGen = false;
        };
    }

    private void OnValidate()
    {
        UpdateTexture();
    }
    void UpdateTexture()
    {
        InitCA();
        SetTexture();
    }
    public void SetTexture()
    {
        m_CellularAutomatumManager = transform.GetComponent<CellularAutomatum>();

        Texture3D tex3D = new Texture3D(m_CellularAutomatumManager.width, m_CellularAutomatumManager.height, m_CellularAutomatumManager.depth, TextureFormat.RGBA32, false);
      //  tex3D.filterMode = FilterMode.Point;
        tex3D.wrapMode = TextureWrapMode.Clamp;
        Graphics.CopyTexture(m_CellularAutomatumManager.automatum, tex3D);

        AssetDatabase.CreateAsset(tex3D, "Assets/Main/3DTexture.asset");

        GetComponent<Renderer>().sharedMaterial.SetTexture("_CellularTex", tex3D);
    }
   
    void ComputeCA()
    {
        int threadGroupsX = Mathf.CeilToInt(m_CellularAutomatumManager.width / 8.0f);
        int threadGroupsY = Mathf.CeilToInt(m_CellularAutomatumManager.height / 8.0f);
        int threadGroupsZ = Mathf.CeilToInt(m_CellularAutomatumManager.depth / 8.0f);

        CA.Dispatch(0, threadGroupsX, threadGroupsY, threadGroupsZ);
    }

    void InitCA()
    {         
        m_CellularAutomatumManager = transform.GetComponent<CellularAutomatum>();
       
        if(m_CellularAutomatumManager.m_generation == 0)
            m_CellularAutomatumManager.InitTexture();

        CA.SetTexture(0, "Automatum", m_CellularAutomatumManager.automatum);
        CA.SetInt("width", m_CellularAutomatumManager.width);
        CA.SetInt("depth", m_CellularAutomatumManager.depth);
        CA.SetInt("height", m_CellularAutomatumManager.height);
        CA.SetInt("currentLayer", m_CellularAutomatumManager.m_generation);

        ComputeCA();        
    }
    public Texture3D CreateTexture3D()
    {
        // Configure the texture
        int size = 3;
        TextureFormat format = TextureFormat.RGBA32;
        TextureWrapMode wrapMode = TextureWrapMode.Clamp;

        Texture3D texture = new Texture3D(size, size, size, format, false);
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

        colors[13] = new Color(0, 0, 0, 1);

        texture.SetPixels(colors);
        texture.Apply();
        return texture;
    }

}