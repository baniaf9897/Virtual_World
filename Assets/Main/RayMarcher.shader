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
            #define MAX_DIST 2
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

          
        /*    float  BlendDst(float a, float b, float k)
            {
                float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
                float blendDst = lerp(b, a, h) - k * h * (1.0 - h);
                return blendDst;
            }

            float SmoothUnionSDF(float distA, float distB, float distC, float distD, float distE, float distF, float k) {
                
            }*/

            float smin(float a, float b, float k)
            {
                float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
                float blendDst = lerp(b, a, h) - k * h * (1.0 - h);
                return blendDst;
            }

          /*  float SMin(float distA, float distB, float distC, float distD, float distE, float distF, float distG, float k)
            {
                float res = exp2(-k * distA) + exp2(-k * distB) + exp2(-k * distC) + exp2(-k * distD) + exp2(-k * distE) + exp2(-k * distF) + exp2(-k * distG);
                return -log2(res) / k;
            }*/

            float3 GetNumCell(float3 p) {
                p = p + 0.499;
                float dimTex = _CellularTex_TexelSize.w;
                float3 numCell = floor(p * dimTex) / dimTex;

                return numCell;
            }

            float3 GetCurrentObjectPos(float3 p) {
                float dimTex = _CellularTex_TexelSize.w;
                float offset = 1.0 / (dimTex * 2.0);
                return  GetNumCell(p) - 0.5 + offset;

            }

            float GetCellNeighborhood(float3 p) {
                
                float d = GetDist(p, GetCurrentObjectPos(p));
                 float k = 0.1;
                float dimTex = _CellularTex_TexelSize.w;
                float offset = 1.0 / (dimTex * 2.0);
                float cellOffset = 1.0 / _CellularTex_TexelSize.w;
                float3 numCell = GetNumCell(p);

                float3 front = numCell.x + cellOffset;
                if (tex3D(_CellularTex, front).a > 0  ) {
                    d = smin(d,GetDist(p, front - 0.5 + offset),k);
                }

                float3 back = numCell.x - cellOffset;
                if (tex3D(_CellularTex, back).a > 0  ) {
                    d = smin(d, GetDist(p, back - 0.5 + offset),k);
                }
                
                float3 left = numCell.z + cellOffset;
                if (tex3D(_CellularTex, left).a >  0) {
                    d = smin(d, GetDist(p, left - 0.5 + offset), k);
                }

                float3 right = numCell.z - cellOffset;
                if (tex3D(_CellularTex, right).a > 0  ) {
                    d = smin(d, GetDist(p, right - 0.5 + offset), k);
                }
                float3 top = numCell.y + cellOffset;
                if (tex3D(_CellularTex, top).a > 0  ) {
                    d = smin(d, GetDist(p, top - 0.5 + offset), k);
                }

                float3 bottom = numCell.y - cellOffset;
                if (tex3D(_CellularTex, bottom).a > 0 ) {
                    d = smin(d, GetDist(p, bottom - 0.5 + offset), k);

                }
                
                

                return d;
            }


            float4 GetCurrentCell(float3 p) {
                return  tex3D(_CellularTex, GetNumCell(p));
            }

           

            float Raymarch(float3 ro, float3 rd) {
                
                float d0 = 0;
                float dS;

                [loop]
                for (int n = 0; n < MAX_STEPS; n++) {
                    float3 p = ro + d0 * rd;
                    float4 c = GetCurrentCell(p);
                 
                    if (c.a > 0.0 && abs(p.x) <  0.5 && abs(p.y) <  0.5 && abs(p.z) <  0.5) {
                        dS = GetDist(p,GetCurrentObjectPos(p));

                       // dS = GetCellNeighborhood(p);
                    }
                    else {
                        dS = 0.01;//  1.0 / _CellularTex_TexelSize.w;
                    }
               
                    d0 += dS;

                    if (dS <= SURF_DIST || d0 >= MAX_DIST) {
                        break;
                    }
                };
                return d0;
            }

            float3 GetNormal(float3 p) {
                float2 e = float2(0.001, 0);

                float3 n = GetDist(p, GetCurrentObjectPos(p)) - float3(
                        GetDist(p - e.xyy, GetCurrentObjectPos(p)),
                        GetDist(p - e.yxy, GetCurrentObjectPos(p)),
                        GetDist(p - e.yyx, GetCurrentObjectPos(p))
                 );

                return normalize(n);
            }


            float CalculateShadow(float3 ro, float3 rd, float dstToShadePoint) {
                float rayDst = 0;
                int marchSteps = 0;
                float shadowIntensity = .2;
                float brightness = 1;

                while (rayDst < dstToShadePoint) {
                    marchSteps++;
                    float dst = GetDist(ro, GetCurrentObjectPos(ro));

                    if (dst <= SURF_DIST) {
                        return shadowIntensity;
                    }

                    brightness = min(brightness, dst * 200);

                    ro += rd * dst;
                    rayDst += dst;
                }
                return shadowIntensity + (1 - shadowIntensity) * brightness;
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
  
                    col =  float4( n, 1);
                }  
         
  
  
                
               
 
               return col;
            }
                ENDHLSL
        }
    }
}
