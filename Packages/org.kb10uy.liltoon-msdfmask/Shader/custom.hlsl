#define LIL_CUSTOM_PROPERTIES        \
    int _CustomAlphaMask2ndMode;     \
    float4 _CustomAlphaMask2nd_ST;   \
    float _CustomAlphaMask2ndScale;  \
    float _CustomAlphaMask2ndValue;  \
    \
    int _CustomUseMsdfMaskAlpha;     \
    int _CustomUseMsdfMaskAlpha2;    \
    int _CustomUseMsdfMaskMain2;     \
    int _CustomUseMsdfMaskMain3;     \
    int _CustomUseMsdfMaskShadow;    \
    int _CustomUseMsdfMaskEmission1; \
    int _CustomUseMsdfMaskEmission2; \
    int _CustomUseMsdfMaskMatCap1;   \
    int _CustomUseMsdfMaskMatCap2;

#define LIL_CUSTOM_TEXTURES \
    TEXTURE2D(_CustomAlphaMask2nd);

#define LIL_CUSTOM_VERT_COPY

#define OVERRIDE_ALPHAMASK lilGetAlphaMsdfMask(fd);
#define OVERRIDE_MAIN2ND lilGetMain2ndMsdfMask(fd, color2nd, main2ndDissolveAlpha LIL_SAMP_IN(sampler_MainTex));
#define OVERRIDE_MAIN3RD lilGetMain3rdMsdfMask(fd, color3rd, main3rdDissolveAlpha LIL_SAMP_IN(sampler_MainTex));
#define OVERRIDE_SHADOW lilGetShadingMsdfMask(fd LIL_SAMP_IN(sampler_MainTex));
#define OVERRIDE_MATCAP lilGetMatCapMsdfMask(fd LIL_SAMP_IN(sampler_MainTex));
#define OVERRIDE_MATCAP2ND lilGetMatCap2ndMsdfMask(fd LIL_SAMP_IN(sampler_MainTex));
#if !defined(LIL_LITE) 
    #define OVERRIDE_EMISSION_1ST lilEmissionMsdfMask(fd LIL_SAMP_IN(sampler_MainTex));
    #define OVERRIDE_EMISSION_2ND lilEmission2ndMsdfMask(fd LIL_SAMP_IN(sampler_MainTex));
#endif
