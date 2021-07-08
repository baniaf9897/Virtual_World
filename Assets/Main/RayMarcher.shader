Shader "Unlit/RayMarcher"
{
    Properties
    {
        _MainTex("_MainTex", 2D) = "white" {}
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100
        Cull off

        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END
        ENDHLSL


        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
  
 
            #define MAX_STEPS 100
            #define MAX_DIST 100
            #define SURF_DIST 0.001

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro: TEXCOORD1;
                float3 hitPos: TEXCOORD2;


            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz);

                o.vertex = positionInputs.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    
                o.ro = _WorldSpaceCameraPos;
                o.hitPos = positionInputs.positionWS;

 
                return o;
            }

            float GetDist(float3 p) {
                float d = length(p) - 0.3;
                return d;
            }

            float Raymarch(float3 ro, float3 rd) {
                
                float d0 = 0;
                float dS;


                for (int n = 0; n < MAX_STEPS; n++) {
                    float3 p = ro + d0 * rd;
                    dS = GetDist(p);
                    d0 += dS;

                    if (dS< SURF_DIST || d0 > MAX_DIST) {
                        break;
                    }
                };
                return d0;
            }

            float3 GetNormal(float3 p) {
                float2 e = float2(0.01, 0);

                float3 n = GetDist(p) - float3(
                        GetDist(p - e.xyy),
                        GetDist(p - e.yxy),
                        GetDist(p - e.yyx)
                 );

                return normalize(n);
            }

            half4 frag(v2f i) : SV_Target
            {
                
                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos - ro);

                float d = Raymarch(ro, rd);
                half4 col = 0;

                if (d >= MAX_DIST) {
                    discard;
                }
                else {
                    float3 p = ro + rd * d;
                    float3 n = GetNormal(p) * float3(1,1,0.5);
                    col.rgb = n;
                }
               
 
               return col;
            }
                ENDHLSL
        }
    }
}
