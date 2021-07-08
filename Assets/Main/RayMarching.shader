Shader "Unlit/RayMarching"
{
    Properties
    {
        _CellularTex("Texture", 3D) = "" {}
        _Alpha("Alpha", float) = 0.02
        _StepSize("Step Size", float) = 0.01
    }
        SubShader
        {
            Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
            Blend One OneMinusSrcAlpha
            LOD 100
            Cull off

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                // Maximum amount of raymarching samples
                #define MAX_STEP_COUNT 128

                // Allowed floating point inaccuracy
                #define EPSILON 0.00001f

                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 uv : TEXCOORD0; // texture coordinate

                };

                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    float3 objectVertex : TEXCOORD0;
                    float3 vectorToSurface : TEXCOORD1;
                    float3 uv: TEXCOORD2;
                };

                sampler3D _CellularTex;            
                float4 _CellularTex_TexelSize;
                float4 _CellularTex_ST;
                float _Alpha;
                float _StepSize;


                float mincomp(in float3 p) { return min(p.x, min(p.y, p.z)); };


                v2f vert(appdata v)
                {
                    v2f o;

                    // Vertex in object space this will be the starting point of raymarching
                    o.objectVertex = v.vertex;

                    // Calculate vector from camera to vertex in world space
                    float3 worldVertex = mul(unity_ObjectToWorld, v.vertex).xyz;
                    o.vectorToSurface = worldVertex - _WorldSpaceCameraPos;

                    o.vertex = UnityObjectToClipPos(v.vertex);

                    o.uv = v.uv;
                    return o;
                }

                float4 BlendUnder(float4 color, float4 newColor)
                {
                    color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
                    color.a += (1.0 - color.a) * newColor.a;
                    return color;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    float3 rayOrigin = i.objectVertex;
                    float3 rayDirection = mul(unity_WorldToObject, float4(normalize(i.vectorToSurface), 1));

                    float4 color = float4(0, 0, 0, 0);
                    float3 samplePosition = rayOrigin;
                    float t = 0;

                    for (int i = 0; i < MAX_STEP_COUNT; i++)
                    {
                         if (max(abs(samplePosition.x), max(abs(samplePosition.y), abs(samplePosition.z))) < 0.5 + EPSILON )
                         {
                             float3 p = rayOrigin + rayDirection * t;
                             float4 c = tex3D(_CellularTex, p / _CellularTex_TexelSize.w);

                             if (c.a > 0.0) {
                                 color = BlendUnder(color, c);
                                 // break;
                             }

                             float3 deltas = (step(0, rayDirection) - frac(p)) / rayDirection;
                             t += max(mincomp(deltas), _StepSize);
                         }
                    }

                    return color;
                }
                ENDCG
            }
        }
}