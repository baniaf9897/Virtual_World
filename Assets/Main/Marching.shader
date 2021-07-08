// Example Shader for Universal RP
// Written by @Cyanilux
// https://cyangamedev.wordpress.com/urp-shader-code/
Shader "Custom/RayMarching" {
	Properties{
		_CellularTex("Cellular Texture", 3D) = "" {}
		_BaseColor("Example Colour", Color) = (0, 0.66, 0.73, 1)
			_StepSize("Step Size", Float) = 0.01
			//_ExampleDir ("Example Vector", Vector) = (0, 1, 0, 0)
			//
			
 	}
		SubShader{
			Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
			   Cull off
			HLSLINCLUDE
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

				CBUFFER_START(UnityPerMaterial)
				float4 _CellularTex_ST;
				float4 _CellularTex_TexelSize;

				float4 _BaseColor;
				float _StepSize;
				//float4 _ExampleDir;
				//float _ExampleFloat;


				CBUFFER_END
					ENDHLSL

					Pass{
						Name "RayMarching"
						Tags { "LightMode" = "UniversalForward" }



						HLSLPROGRAM
						#pragma vertex vert
						#pragma fragment frag


 				#define MAX_STEP_COUNT 100
 
				struct Attributes {
					float4 position	: POSITION;
					float3 uv		: TEXCOORD0;
					float4 color		: COLOR;
				};

				struct Varyings {
					float4 positionCS 	: SV_POSITION;
					float3 positionWS	:TEXCOORD0;
					float3 positionOS : TEXCOORD1;
					float3 uv		: TEXCOORD2;
					float4 color		: COLOR;
				};

				TEXTURE3D(_CellularTex);
				SAMPLER(sampler_CellularTex);
				 
				Varyings vert(Attributes IN) {
					Varyings OUT;

					VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.position.xyz);
					OUT.positionCS = positionInputs.positionCS;
					OUT.positionWS = positionInputs.positionWS.xyz; 
					OUT.positionOS = IN.position.xyz;
					OUT.uv = IN.uv;//.xyz * _CellularTex_ST.xyz + _CellularTex_ST.zw;// TRANSFORM_TEX(IN.uv, _CellularTex);
					OUT.color = IN.color;
					return OUT;
				}

				float4 BlendUnder(float4 color, float4 newColor)
				{
					color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
					color.a += (1.0 - color.a) * newColor.a;
					return color;
				}

				float mincomp(in float3 p) { return min(p.x, min(p.y, p.z)); };

				float DistanceCell(float3 eye, float3 centre, float3 size) {
					float3 o = abs(eye - centre) - size;
					float ud = length(max(o, 0));
					float n = max(max(min(o.x, 0), min(o.y, 0)), min(o.z, 0));
					return ud + n;
				}	

				float4 RayMarching(float3 rPos, float3 rDir, float3 pos, float4 c) {
					float4 color = float4(0, 0, 0, 0);
					float MAX_DIST = 10;
					int MAX_STEPS = 100;

					int steps = 0;
					float SURF_DIST = 0.01;
					float rayDist = 0;
					float dist = 0;
					float3 size = float3(0.01, 0.01, 0.01);


					//return c;

					 
					[loop]
					while (rayDist < MAX_DIST && steps < MAX_STEPS) {

						dist = DistanceCell(rPos,pos,size);

						if (dist <= SURF_DIST) {
							return c;
						};

						rPos += rDir * dist;
						rayDist += dist;
						steps++;
					};


					return color; 
				}

				half4 frag(Varyings i) : SV_Target {
				
					float3 vectorToSurface = i.positionWS -_WorldSpaceCameraPos ;

					float3 rayOrigin = i.positionOS;
					float3 rayDirection = normalize(vectorToSurface);

					float4 color = float4(0, 0, 0, 0);
					float3 samplePosition = rayOrigin;
					float t = 0;
				
					color = SAMPLE_TEXTURE3D(_CellularTex, sampler_CellularTex, samplePosition / _CellularTex_TexelSize.w);

					if (color.a < 0.99) {
						discard;
					}


					/*[loop]
					while (t < 1)
					{
						if (max(abs(samplePosition.x), max(abs(samplePosition.y), abs(samplePosition.z))) < 0.5 + _StepSize)
						{
							samplePosition = rayOrigin + rayDirection * t;
							float4 c = SAMPLE_TEXTURE3D(_CellularTex, sampler_CellularTex, samplePosition);
 
							if (c.a > 0.0) {
								color = c;// RayMarching(p, rayDirection, p / _CellularTex_TexelSize.w, c);//BlendUnder(color,   );
								break;
							}

							float3 deltas = (step(0, rayDirection) - frac(samplePosition)) / rayDirection;
							t += max(mincomp(deltas), _StepSize);
						}
					}*/

					return color;

				}
				ENDHLSL
			}
		}
}