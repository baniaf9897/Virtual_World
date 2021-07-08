Shader "Unlit/RayMarcher"
{
    Properties
    {
                _MainTex("_MainTex", 2D) = "" {}

        _CellularTex("_CellularTex", 3D) = "" {}

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
  
 
            #define MAX_STEPS 200
            #define MAX_DIST 100
            #define SURF_DIST 0.001

            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro: TEXCOORD1;
                float3 hitPos: TEXCOORD2;


            };
 

            sampler3D _CellularTex;
            float4 _CellularTex_ST;
            float4 _CellularTex_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz);

                o.vertex = positionInputs.positionCS;
                o.uv = v.uv;
                    
                o.ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));
                o.hitPos = v.vertex;

 
                return o;
            }


            float mincomp(in float3 p) { return min(p.x, min(p.y, p.z)); };


            float GetDist(float3 p, float3 pos) {
                float d = length(p + pos) - 0.1;

                return d;
            }

            float4 GetCurrentCell(float3 p) {
                return tex3D(_CellularTex,p);
            }

            float Raymarch(float3 ro, float3 rd) {
                
                float d0 = 0;
                float dS;

               
                for (int n = 0; n < MAX_STEPS; n++) {
                    float3 p = ro + d0 * rd;
                   // dS = GetDist(p,float3(0,0,0));

                    //check if the current cell is filled
                    //if yes => calc dist to current cell
                    //if no => go to next cell
                    float4 c = GetCurrentCell(p);
                    if (c.a > 0.9) {
                        // position of object in cell == .xyz

                        dS = GetDist(p,c.xyz -float3(0.25,0.25,0.25));

                    }
                    else {
                        //go to next cell
                        //how to get distance to next cell ?
                        dS = 1.0f;//_CellularTex_TexelSize.xyz;//;max(mincomp(deltas), 0.01);
                    }

                    d0 += dS;

                    if (dS< SURF_DIST || d0 > MAX_DIST) {
                        break;
                    }
                };
                return d0;
            }

            float3 GetNormal(float3 p) {
                float2 e = float2(0.01, 0);

                float3 n = GetDist(p, float3(0, 0, 0)) - float3(
                        GetDist(p - e.xyy, float3(0, 0, 0)),
                        GetDist(p - e.yxy, float3(0, 0, 0)),
                        GetDist(p - e.yyx, float3(0, 0, 0))
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
                    float3 n = GetNormal(p);
                    col.rgb = n;
                }
               
 
               return col;
            }
                ENDHLSL
        }
    }
}
