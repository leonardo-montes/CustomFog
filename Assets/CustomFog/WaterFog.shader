Shader "Hidden/NewImageEffectShader" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader {
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldDirection : TEXCOORD1;
			};

			sampler2D _CameraDepthTexture;
			float4x4 clipToWorld;

			v2f vert (appdata v) {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				UNITY_TRANSFER_DEPTH(o.depth);
				
				float4 cli = float4(o.vertex.xy, 0.0, 1.0);
				o.worldDirection = mul(clipToWorld, cli) - _WorldSpaceCameraPos;

				return o;
			}
			
			sampler2D _MainTex;
			uniform half4 _Fog0Color;
			uniform half4 _Fog1Color;
			uniform half _HeightPower;
			uniform half _HeightOffset;

			uniform half _BlurDepthPow;

			sampler2D _BlurDepth;

			sampler2D _Falloff;

			fixed4 frag (v2f i) : SV_Target {
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy);
				float depthEye = LinearEyeDepth(depth);	
				float falloff = 1 - tex2D(_Falloff, float2(Linear01Depth(depth), 0)).r;

				float3 worldspace = i.worldDirection * depthEye + _WorldSpaceCameraPos;

				float4 blurDepth = tex2D(_BlurDepth, i.uv);


				fixed4 col = tex2D(_MainTex, i.uv);

				half4 gradient = lerp(_Fog0Color, _Fog1Color, saturate((worldspace.y - _HeightOffset) / _HeightPower));
				col = lerp(col, gradient, falloff);
				col += blurDepth * _BlurDepthPow;

				//col = depth;
				//col = falloff;
				//col = blurDepth;

				return col;
			}
			ENDCG
		}
	}
}
