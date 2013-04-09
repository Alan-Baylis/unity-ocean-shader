Shader "Water" {
Properties {
	_deepColor ("Deep color", COLOR)  = ( .172 , .463 , .435 , 0)
	_WaveScale ("Wave scale", Range (0.02,0.15)) = .07
	_ColorControl ("Reflective color (RGB) fresnel (A) ", 2D) = "" { }
	//_ColorControlCube ("Reflective color cube (RGB) fresnel (A) ", Cube) = "" { TexGen CubeReflect }
	_BumpMap ("Waves Normalmap ", 2D) = "" { }
	WaveSpeed ("Wave speed (map1 x,y; map2 x,y)", Vector) = (19,9,-16,-7)
	
	//For specular
	_SpecColor("Specular Color", Color) = (1, 1, 1, 1)
	_Shininess("Shininess", Float) = 10
	
	//Reflection
	 _Cube("Reflection Map", Cube) = "" {}
	
}

CGINCLUDE
// -----------------------------------------------------------
// This section is included in all program sections below

#include "UnityCG.cginc"
uniform float4 _deepColor;
uniform float4 WaveSpeed;
uniform float _WaveScale;
uniform float4 _WaveOffset;

//For specular
uniform float4 _SpecColor; 
uniform float _Shininess;
uniform float3 _worldspaceCameraPos;
uniform float4 _LightColor0; 

//Reflection
uniform samplerCUBE _Cube; 

struct vertexInput {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	
	float4 tangent : TANGENT;
};

struct vertexOutput {
	float4 pos : SV_POSITION;
	float2 bumpuv[2] : TEXCOORD0;
	float3 viewDir : TEXCOORD2;
	//for specular
	float4 posWorld : TEXCOORD3;
	float3 normalDir : TEXCOORD4;
	
	float3 tangentWorld : TEXCOORD6;
	float3 normalWorld : TEXCOORD7;
    float3 binormalWorld : TEXCOORD5;
};

vertexOutput vert(vertexInput v)
{
	vertexOutput o;
	float4 s;

	o.pos = mul (UNITY_MATRIX_MVP, v.vertex);

	// scroll bump waves
	float4 temp;
	temp.xyzw = v.vertex.xzxz * _WaveScale / unity_Scale.w + _WaveOffset;
	o.bumpuv[0] = temp.xy * float2(.5, .5);
	o.bumpuv[1] = temp.wz;
	//o.bumpuv[0] = v.vertex.xzxz * _WaveScale;
	//o.bumpuv[1] = v.vertex.xzxz * _WaveScale;
	
	// object space view direction
	o.viewDir.xzy = normalize( ObjSpaceViewDir(v.vertex) );
	
	//for specular
	o.posWorld = mul(_Object2World, v.vertex);
	o.normalDir = normalize(float3(mul(float4(v.normal, 0.0), _World2Object)));
	
	//testing only
	o.tangentWorld = normalize(float3(
    			mul(_Object2World, float4(float3(v.tangent), 0.0))));
	o.normalWorld = normalize(
               mul(float4(v.normal, 0.0), _World2Object));
    o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w); // tangent.w is specific to Unity
	return o;
}

ENDCG
	
// -----------------------------------------------------------
// Fragment program

Subshader {
	Tags { "Queue" = "Transparent" }
	Pass {


Blend SrcAlpha OneMinusSrcAlpha // use alpha blending

CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest 

sampler2D _BumpMap;
sampler2D _ColorControl;

half4 frag(vertexOutput i ) : COLOR
{
	half3 bump1 = UnpackNormal(tex2D( _BumpMap, i.bumpuv[0] )).rgb;
	half3 bump2 = UnpackNormal(tex2D( _BumpMap, i.bumpuv[1] )).rgb;
	half3 bump = (bump1 + bump2) * 0.5;	
	half4 col;
	
	//Begin Specular
	float3 normalDirection = normalize(i.normalDir);
	float3 viewDirection = normalize(_WorldSpaceCameraPos - float3(i.posWorld));
	float3 lightDirection;
    float attenuation;
 
     		if (0.0 == _WorldSpaceLightPos0.w) // directional light?
            {
               attenuation = 1.0; // no attenuation
               lightDirection = normalize(float3(_WorldSpaceLightPos0));
            } 
            else // point or spot light
            {
               float3 vertexToLightSource = float3(_WorldSpaceLightPos0 - i.posWorld);
               float distance = length(vertexToLightSource);
               attenuation = 1.0 / distance; // linear attenuation 
               lightDirection = normalize(vertexToLightSource);
           }
           
           
            float3 specularReflection;
            if (dot(normalDirection, lightDirection) < 0.0) 
            // light source on the wrong side?
            {
               specularReflection = float3(0.0, 0.0, 0.0); 
            }
            else // light source on the right side
            {
               specularReflection = attenuation * float3(_LightColor0) 
                  * float3(_SpecColor) * pow(max(0.0, dot(
                  reflect(-lightDirection, bump), 
                  viewDirection)), _Shininess);
            }
	//End Specular
	
		
	//Testing (Convert normal map to world space)
	float3x3 local2WorldTranspose = float3x3(i.tangentWorld, i.binormalWorld, i.normalWorld);
	normalDirection = normalize(mul(bump, local2WorldTranspose));
	
	//half fresnel = dot( i.viewDir, i.normalDir);
	col.rgb = float3(0,0,0);
	//half fresnel = pow(1.0 - dot(viewDirection, reflect(viewDirection, bumpWorld)), 1.0);
	//half fresnel = dot(viewDirection, reflect(viewDirection, bumpWorld));
	float base = dot(viewDirection, i.normalDir);
	float fresnel = pow(1.0 -base, 1.5);
		
	if(fresnel < 0.0) {
		fresnel = 0.0;
	}
	else if(fresnel > 1.0) {
		//col.rgb = (-0.1, -0.1, -0.1) * fresnel;
		fresnel = 1.0;
	}
		
	//Reflection
	float3 reflectedDir = reflect(i.viewDir, bump * 1.0);
    float3 reflectedColor = texCUBE(_Cube, reflectedDir);

	//col.rgb += normalDirection;
	//col.rgb = lerp(float3(0,0,0),float3(1,1,1), fresnel);
	col.a = lerp(0.5, 1.0, fresnel);
	//col.rgb += reflectedColor;
	col.rgb += lerp(_deepColor, reflectedColor, fresnel);
	//col.rgb = float3(1.0, 1.0, 1.0) * specularReflection + (reflectedColor * 0.0) + (_horizonColor.rgb * 1.0);
	//col.rgb = lerp( water.rgb, _horizonColor.rgb, water.a );
	return col;
}
ENDCG
	}
}

}
