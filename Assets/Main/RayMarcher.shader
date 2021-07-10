Shader "Unlit/RayMarcher"
{
    Properties
    {
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
  
 
            #define MAX_STEPS 300
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
                o.hitPos = v.vertex.xyz;

 
                return o;
            }


            float mincomp(in float3 p) { return min(p.x, min(p.y, p.z)); };


            float GetDist(float3 p, float3 pos) {
                float d = length(p  - pos) - (1.0/ (_CellularTex_TexelSize.w * 4));

                return d;
            }

            float3 GetNumCell(float3 p) {
                p = p + 0.499;
                float dimTex = _CellularTex_TexelSize.w;
                float3 numCell = floor(p * dimTex) / dimTex;
                
                return numCell  ;
            }

            float4 GetCurrentCell(float3 p) {
                return  tex3D(_CellularTex, GetNumCell(p));
            }

            float3 GetCurrentObjectPos(float3 p) {
                float dimTex = _CellularTex_TexelSize.w;
                float offset = 1.0 / (dimTex * 2.0);
                return  GetNumCell(p) - 0.5 + offset;
               
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
                
 
                     if (c.a > 0.0 && abs(p.x) < 0.5 && abs(p.y) < 0.5 && abs(p.z) < 0.5) {
                        // position of object in cell == .xyz

                        dS = GetDist(p,GetCurrentObjectPos(p));

                    }
                    else {
                        //go to next cell
                        dS = 0.01;//_CellularTex_TexelSize.xyz;//;max(mincomp(deltas), 0.01);
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

                float3 n = GetDist(p, GetCurrentObjectPos(p)) - float3(
                        GetDist(p - e.xyy, GetCurrentObjectPos(p)),
                        GetDist(p - e.yxy, GetCurrentObjectPos(p)),
                        GetDist(p - e.yyx, GetCurrentObjectPos(p))
                 );

                return normalize(n);
            }

            half4 frag(v2f i) : SV_Target
            {
                
                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos - ro);

                float d = Raymarch(ro, rd);
                half4 col = 1;

              
                 if(d >= MAX_DIST) {
                    discard;
                    //col.rgb = GetNumCell(i.hitPos);
                }
                else {
                    float3 p =  ro + rd * d;
                    float3 n = GetNormal(p);

                    col.rgb = n;
                }  
         
  
  
                
               
 
               return col;
            }
                ENDHLSL
        }
    }
}
