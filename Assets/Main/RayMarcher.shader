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
  
 
            #define MAX_STEPS 800
            #define MAX_DIST 2.0
            #define SURF_DIST 0.0005

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
            float maxcomp(in float3 p) { return max(p.x, max(p.y, p.z)); };


            float GetDist(float3 p, float3 pos) {
                //float d = length(p  - pos) - (1.0/ (_CellularTex_TexelSize.w *4));

               // return d;

                float3 d = abs(p - pos) - (1.0 / (_CellularTex_TexelSize.w * 2));
                return length(max(d, 0.0)) + min(maxcomp(d), 0.0);
            }
 
            float smin(float a, float b, float k)
            {
                float h = max(k - abs(a - b), 0.0) / k;
                return min(a, b) - h * h * h * k * (1.0 / 6.0);
            }
 

            float3 GetNumCell(float3 p) {
                p = p + 0.4999;
                float dimTex = _CellularTex_TexelSize.w;
                float3 numCell = floor(p * dimTex) / dimTex;

                
                return numCell;
            }

            float3 GetCurrentObjectPos(float3 p) {
                float dimTex =  _CellularTex_TexelSize.w;
                float offset = 1.0 / (dimTex * 2.0);
                return  GetNumCell(p) - 0.5 + offset;

            }

            float smin3(float a, float b, float c, float k) {
                a = pow(a, k);
                b = pow(b, k);
                c = pow(c, k);

                return pow((a * b * c) / (a * b + b * c + a * c), 1.0 / k);
            }

            float GetCellNeighborhood(float3 p) {
                
                float d = GetDist(p, GetCurrentObjectPos(p));
                float k = 0.1;
                float dimTex = _CellularTex_TexelSize.w;
                float offset = 1.0 / (dimTex * 2.0);
                float cellOffset = 1.0 / _CellularTex_TexelSize.w;
                float3 numCell = GetNumCell(p);

                float fD = 0;
                float bD = 0;
                float lD = 0;
                float rD = 0;
                float tD = 0;
                float boD = 0;


                float3 front = p;
                front.x += cellOffset;
                fD = GetDist(p, GetCurrentObjectPos(front));


                float3 back = numCell;
                back.x -= cellOffset;
                bD = GetDist(p, back - 0.5 + offset) ;


                float3 left = numCell;
                left.z += cellOffset;
                lD = GetDist(p, left - 0.5 + offset) ;


                float3 right = numCell;
                right.z -= cellOffset;
                rD =  GetDist(p, right - 0.5 + offset) ;

                float3 top = numCell;
                top.y += cellOffset;
                tD = GetDist(p, top - 0.5 + offset) ;


                float3 bottom = numCell;
                bottom.y -= cellOffset;
                boD = GetDist(p, bottom - 0.5 + offset);

                float fbl = smin3(fD, bD, lD, 8);
                float rtb = smin3(rD, tD, boD, 8);

 
              
                d =  smin(d, fD, 0.015) ;
                d = smin(d, bD, 0.015);
                d = smin(d, tD, 0.02);
                d = smin(d, boD, 0.02);

                return d;
            }


            float4 GetCurrentCell(float3 p) {

                float3 numCell = GetNumCell(p);
                if (numCell.x < 0.0 || numCell.y < 0.0 || numCell.z < 0.0 || numCell.x > 1.0 || numCell.y > 1.0 || numCell.z > 1.0) {
                    return float4(0, 0, 0, 0);
                }

                return  tex3D(_CellularTex, GetNumCell(p));
            }

           

            float2 Raymarch(float3 ro, float3 rd) {
                
                float d0 = 0;
                float dS;

                [loop]
                for (int n = 0; n < MAX_STEPS; n++) {
                    float3 p = ro + d0 * rd;
                    float4 c = GetCurrentCell(p);

                    if (c.a > 0.0  ) {
                        dS =  GetDist(p, GetCurrentObjectPos(p));
                        
                       //dS = GetCellNeighborhood(p);
                    }
                    else {

                         float3 pCellSpace = p * _CellularTex_TexelSize.w;
                         float3 rdCellSpace = rd * _CellularTex_TexelSize.w;

                         float3 deltas = (ceil(pCellSpace) - pCellSpace) / rdCellSpace;
                         dS =   max(mincomp(deltas), SURF_DIST + 0.0005);
                         

                        //dS = 0.01;// max(SURF_DIST, 1.0 / (_CellularTex_TexelSize.w * 2));// 1.0 / (_CellularTex_TexelSize.w * 2);
                    }
               
                    d0 += dS;

                    if (dS <= SURF_DIST || d0 > MAX_DIST) {
                        break;
                    }
                };
                return float2(d0,dS);
            }

            float3 GetNormal(float3 p) {
                float2 e = float2(0.0001, 0);

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



            half4 frag(v2f i, int facing:VFACE) : SV_Target
            {

 
                  
                
                
                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos - ro);

                float2 d = Raymarch(ro, rd);
                half4 col = 1;

              
                 if(d.y > SURF_DIST ) {
                    discard;
                    //col.rgb = GetNumCell(i.hitPos);
                }
                else {
                    float3 _Light = float3(5, 10, 0);
                    float3 p =  ro + rd * d.x;
                    float3 n = GetNormal(p);

         
                    float3 lightDir =   normalize(_Light - ro);
                    float lighting =  saturate(saturate(dot(n, lightDir)));
                    float3 color = float3(1, 0.5, 1  - (2*p.y));

 
                       
                    if (d.x > 0.5) {
                        color = float3(1, 1, 1);
                    }
                     
                    col = float4(color * lighting , 1);
                }  
         
  
  
                
               
 
               return col;
               
            }
                ENDHLSL
        }
    }
}
