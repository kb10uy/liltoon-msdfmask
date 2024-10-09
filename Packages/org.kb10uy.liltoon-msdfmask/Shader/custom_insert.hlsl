float4 lilMsdfMaskSDF(float4 input) {
    return step(float4(0.5, 0.5, 0.5, 0.5), input);
}

float4 lilMsdfMaskAlphaBlend(float4 bg, float4 fg) {
    float alpha = lerp(bg.a, 1.0, fg.a);
    float3 color = lerp(bg.rgb * bg.a, fg.rgb, fg.a) / max(alpha, 0.001);
    return float4(lerp(float3(0.0, 0.0, 0.0), color, step(0.001, alpha)), alpha);
}

// Alpha Mask / 2nd
#if defined(LIL_FEATURE_ALPHAMASK)
    void lilGetAlphaMsdfMask(inout lilFragData fd)
    {
        if (_AlphaMaskMode)
        {
            float4 maskColor = LIL_SAMPLE_2D_ST(_AlphaMask, sampler_MainTex, fd.uvMain);
            float maskValue = maskColor.r;
            if (_CustomUseMsdfMaskAlpha == 1) maskValue = lilMSDF(maskColor.rgb) * maskColor.a;
            if (_CustomUseMsdfMaskAlpha == 2) maskValue = 1.0 - lilMSDF(maskColor.rgb) * maskColor.a;

            float alphaMask = saturate(maskValue * _AlphaMaskScale + _AlphaMaskValue);
            if(_AlphaMaskMode == 1) fd.col.a = alphaMask;
            if(_AlphaMaskMode == 2) fd.col.a = fd.col.a * alphaMask;
            if(_AlphaMaskMode == 3) fd.col.a = saturate(fd.col.a + alphaMask);
            if(_AlphaMaskMode == 4) fd.col.a = saturate(fd.col.a - alphaMask);
        }

        if (_CustomAlphaMask2ndMode)
        {
            float4 maskColor2 = LIL_SAMPLE_2D_ST(_CustomAlphaMask2nd, sampler_MainTex, fd.uvMain);
            float maskValue2 = maskColor2.r;
            if (_CustomUseMsdfMaskAlpha2 == 1) maskValue2 = lilMSDF(maskColor2.rgb) * maskColor2.a;
            if (_CustomUseMsdfMaskAlpha2 == 2) maskValue2 = 1.0 - lilMSDF(maskColor2.rgb) * maskColor2.a;

            float alphaMask2 = saturate(maskValue2 * _CustomAlphaMask2ndScale + _CustomAlphaMask2ndValue);
            if(_CustomAlphaMask2ndMode == 1) fd.col.a = alphaMask2;
            if(_CustomAlphaMask2ndMode == 2) fd.col.a = fd.col.a * alphaMask2;
            if(_CustomAlphaMask2ndMode == 3) fd.col.a = saturate(fd.col.a + alphaMask2);
            if(_CustomAlphaMask2ndMode == 4) fd.col.a = saturate(fd.col.a - alphaMask2);
        }
    }
#else
    #undef OVERRIDE_ALPHAMASK
#endif

// Main 2nd
#if defined(LIL_FEATURE_MAIN2ND)
    void lilGetMain2ndMsdfMask(inout lilFragData fd, inout float4 color2nd, inout float main2ndDissolveAlpha LIL_SAMP_IN_FUNC(samp))
    {
        #if !(defined(LIL_FEATURE_DECAL) && defined(LIL_FEATURE_ANIMATE_DECAL))
            float4 _Main2ndTexDecalAnimation = 0.0;
            float4 _Main2ndTexDecalSubParam = 0.0;
        #endif
        #if !defined(LIL_FEATURE_DECAL)
            bool _Main2ndTexIsDecal = false;
            bool _Main2ndTexIsLeftOnly = false;
            bool _Main2ndTexIsRightOnly = false;
            bool _Main2ndTexShouldCopy = false;
            bool _Main2ndTexShouldFlipMirror = false;
            bool _Main2ndTexShouldFlipCopy = false;
        #endif
        color2nd = _Color2nd;
        if(_UseMain2ndTex)
        {
            float2 uv2nd = fd.uv0;
            if(_Main2ndTex_UVMode == 1) uv2nd = fd.uv1;
            if(_Main2ndTex_UVMode == 2) uv2nd = fd.uv2;
            if(_Main2ndTex_UVMode == 3) uv2nd = fd.uv3;
            if(_Main2ndTex_UVMode == 4) uv2nd = fd.uvMat;
            #if defined(LIL_FEATURE_Main2ndTex)
                if (_CustomLayeredSdfMode == 1) {
                    // LIL_GET_SUBTEX reflects decal mask into A channel
                    float4 sdfValue = lilMsdfMaskSDF(LIL_GET_SUBTEX(_Main2ndTex, uv2nd));
                    color2nd = lilMsdfMaskAlphaBlend(color2nd, _CustomLayeredSdfColorB * sdfValue.b * sdfValue.a);
                    color2nd = lilMsdfMaskAlphaBlend(color2nd, _CustomLayeredSdfColorG * sdfValue.g * sdfValue.a);
                    color2nd = lilMsdfMaskAlphaBlend(color2nd, _CustomLayeredSdfColorR * sdfValue.r * sdfValue.a);
                } else {
                    color2nd *= LIL_GET_SUBTEX(_Main2ndTex, uv2nd);
                }
            #endif
            #if defined(LIL_FEATURE_Main2ndBlendMask)
                // MSDF Mask Process
                float4 maskColor = LIL_SAMPLE_2D(_Main2ndBlendMask, samp, fd.uvMain);
                float maskValue = maskColor.r;
                if (_CustomUseMsdfMaskMain2 == 1) maskValue = lilMSDF(maskColor.rgb) * maskColor.a;
                if (_CustomUseMsdfMaskMain2 == 2) maskValue = 1.0 - lilMSDF(maskColor.rgb) * maskColor.a;
                color2nd.a *= maskValue;
            #endif

            #if defined(LIL_FEATURE_Main2ndDissolveMask)
                #define _Main2ndDissolveMaskEnabled true
            #else
                #define _Main2ndDissolveMaskEnabled false
            #endif

            #if defined(LIL_FEATURE_LAYER_DISSOLVE)
                #if defined(LIL_FEATURE_Main2ndDissolveNoiseMask)
                    lilCalcDissolveWithNoise(
                        color2nd.a,
                        main2ndDissolveAlpha,
                        fd.uv0,
                        fd.positionOS,
                        _Main2ndDissolveParams,
                        _Main2ndDissolvePos,
                        _Main2ndDissolveMask,
                        _Main2ndDissolveMask_ST,
                        _Main2ndDissolveMaskEnabled,
                        _Main2ndDissolveNoiseMask,
                        _Main2ndDissolveNoiseMask_ST,
                        _Main2ndDissolveNoiseMask_ScrollRotate,
                        _Main2ndDissolveNoiseStrength,
                        samp
                    );
                #else
                    lilCalcDissolve(
                        color2nd.a,
                        main2ndDissolveAlpha,
                        fd.uv0,
                        fd.positionOS,
                        _Main2ndDissolveParams,
                        _Main2ndDissolvePos,
                        _Main2ndDissolveMask,
                        _Main2ndDissolveMask_ST,
                        _Main2ndDissolveMaskEnabled,
                        samp
                    );
                #endif
            #endif
            #if defined(LIL_FEATURE_AUDIOLINK)
                if(_AudioLink2Main2nd) color2nd.a *= fd.audioLinkValue;
            #endif
            color2nd.a = lerp(color2nd.a, color2nd.a * saturate((fd.depth - _Main2ndDistanceFade.x) / (_Main2ndDistanceFade.y - _Main2ndDistanceFade.x)), _Main2ndDistanceFade.z);
            if(_Main2ndTex_Cull == 1 && fd.facing > 0 || _Main2ndTex_Cull == 2 && fd.facing < 0) color2nd.a = 0;
            #if LIL_RENDER != 0
                if(_Main2ndTexAlphaMode != 0)
                {
                    if(_Main2ndTexAlphaMode == 1) fd.col.a = color2nd.a;
                    if(_Main2ndTexAlphaMode == 2) fd.col.a = fd.col.a * color2nd.a;
                    if(_Main2ndTexAlphaMode == 3) fd.col.a = saturate(fd.col.a + color2nd.a);
                    if(_Main2ndTexAlphaMode == 4) fd.col.a = saturate(fd.col.a - color2nd.a);
                    color2nd.a = 1;
                }
            #endif
            fd.col.rgb = lilBlendColor(fd.col.rgb, color2nd.rgb, color2nd.a * _Main2ndEnableLighting, _Main2ndTexBlendMode);
        }
    }
#else
    #undef OVERRIDE_MAIN2ND
#endif

// Main 3rd
#if defined(LIL_FEATURE_MAIN3RD)
    void lilGetMain3rdMsdfMask(inout lilFragData fd, inout float4 color3rd, inout float main3rdDissolveAlpha LIL_SAMP_IN_FUNC(samp))
    {
        #if !(defined(LIL_FEATURE_DECAL) && defined(LIL_FEATURE_ANIMATE_DECAL))
            float4 _Main3rdTexDecalAnimation = 0.0;
            float4 _Main3rdTexDecalSubParam = 0.0;
        #endif
        #if !defined(LIL_FEATURE_DECAL)
            bool _Main3rdTexIsDecal = false;
            bool _Main3rdTexIsLeftOnly = false;
            bool _Main3rdTexIsRightOnly = false;
            bool _Main3rdTexShouldCopy = false;
            bool _Main3rdTexShouldFlipMirror = false;
            bool _Main3rdTexShouldFlipCopy = false;
        #endif
        color3rd = _Color3rd;
        if(_UseMain3rdTex)
        {
            float2 uv3rd = fd.uv0;
            if(_Main3rdTex_UVMode == 1) uv3rd = fd.uv1;
            if(_Main3rdTex_UVMode == 2) uv3rd = fd.uv2;
            if(_Main3rdTex_UVMode == 3) uv3rd = fd.uv3;
            if(_Main3rdTex_UVMode == 4) uv3rd = fd.uvMat;
            #if defined(LIL_FEATURE_Main3rdTex)
                if (_CustomLayeredSdfMode == 2) {
                    // LIL_GET_SUBTEX reflects decal mask into A channel
                    float4 sdfValue = lilMsdfMaskSDF(LIL_GET_SUBTEX(_Main3rdTex, uv3rd));
                    color3rd = lilMsdfMaskAlphaBlend(color3rd, _CustomLayeredSdfColorB * sdfValue.b * sdfValue.a);
                    color3rd = lilMsdfMaskAlphaBlend(color3rd, _CustomLayeredSdfColorG * sdfValue.g * sdfValue.a);
                    color3rd = lilMsdfMaskAlphaBlend(color3rd, _CustomLayeredSdfColorR * sdfValue.r * sdfValue.a);
                } else {
                    color3rd *= LIL_GET_SUBTEX(_Main3rdTex, uv3rd);
                }
            #endif
            #if defined(LIL_FEATURE_Main3rdBlendMask)
                // MSDF Mask Process
                float4 maskColor = LIL_SAMPLE_2D(_Main3rdBlendMask, samp, fd.uvMain);
                float maskValue = maskColor.r;
                if (_CustomUseMsdfMaskMain3 == 1) maskValue = lilMSDF(maskColor.rgb) * maskColor.a;
                if (_CustomUseMsdfMaskMain3 == 2) maskValue = 1.0 - lilMSDF(maskColor.rgb) * maskColor.a;
                color3rd.a *= maskValue;
            #endif

            #if defined(LIL_FEATURE_Main3rdDissolveMask)
                #define _Main3rdDissolveMaskEnabled true
            #else
                #define _Main3rdDissolveMaskEnabled false
            #endif

            #if defined(LIL_FEATURE_LAYER_DISSOLVE)
                #if defined(LIL_FEATURE_Main3rdDissolveNoiseMask)
                    lilCalcDissolveWithNoise(
                        color3rd.a,
                        main3rdDissolveAlpha,
                        fd.uv0,
                        fd.positionOS,
                        _Main3rdDissolveParams,
                        _Main3rdDissolvePos,
                        _Main3rdDissolveMask,
                        _Main3rdDissolveMask_ST,
                        _Main3rdDissolveMaskEnabled,
                        _Main3rdDissolveNoiseMask,
                        _Main3rdDissolveNoiseMask_ST,
                        _Main3rdDissolveNoiseMask_ScrollRotate,
                        _Main3rdDissolveNoiseStrength,
                        samp
                    );
                #else
                    lilCalcDissolve(
                        color3rd.a,
                        main3rdDissolveAlpha,
                        fd.uv0,
                        fd.positionOS,
                        _Main3rdDissolveParams,
                        _Main3rdDissolvePos,
                        _Main3rdDissolveMask,
                        _Main3rdDissolveMask_ST,
                        _Main3rdDissolveMaskEnabled,
                        samp
                    );
                #endif
            #endif
            #if defined(LIL_FEATURE_AUDIOLINK)
                if(_AudioLink2Main3rd) color3rd.a *= fd.audioLinkValue;
            #endif
            color3rd.a = lerp(color3rd.a, color3rd.a * saturate((fd.depth - _Main3rdDistanceFade.x) / (_Main3rdDistanceFade.y - _Main3rdDistanceFade.x)), _Main3rdDistanceFade.z);
            if(_Main3rdTex_Cull == 1 && fd.facing > 0 || _Main3rdTex_Cull == 2 && fd.facing < 0) color3rd.a = 0;
            #if LIL_RENDER != 0
                if(_Main3rdTexAlphaMode != 0)
                {
                    if(_Main3rdTexAlphaMode == 1) fd.col.a = color3rd.a;
                    if(_Main3rdTexAlphaMode == 2) fd.col.a = fd.col.a * color3rd.a;
                    if(_Main3rdTexAlphaMode == 3) fd.col.a = saturate(fd.col.a + color3rd.a);
                    if(_Main3rdTexAlphaMode == 4) fd.col.a = saturate(fd.col.a - color3rd.a);
                    color3rd.a = 1;
                }
            #endif
            fd.col.rgb = lilBlendColor(fd.col.rgb, color3rd.rgb, color3rd.a * _Main3rdEnableLighting, _Main3rdTexBlendMode);
        }
    }
#else
    #undef OVERRIDE_MAIN3RD
#endif

// Shadow
#if defined(LIL_FEATURE_SHADOW)
    void lilGetShadingMsdfMask(inout lilFragData fd LIL_SAMP_IN_FUNC(samp))
    {
        if(_UseShadow)
        {
            // Normal
            float3 N1 = fd.N;
            float3 N2 = fd.N;
            #if defined(LIL_FEATURE_SHADOW_3RD)
                float3 N3 = fd.N;
            #endif
            #if defined(LIL_FEATURE_NORMAL_1ST) || defined(LIL_FEATURE_NORMAL_2ND)
                N1 = lerp(fd.origN, fd.N, _ShadowNormalStrength);
                N2 = lerp(fd.origN, fd.N, _Shadow2ndNormalStrength);
                #if defined(LIL_FEATURE_SHADOW_3RD)
                    N3 = lerp(fd.origN, fd.N, _Shadow3rdNormalStrength);
                #endif
            #endif

            float4 shadowStrengthMask = 1;
            #if defined(LIL_FEATURE_ShadowStrengthMask)
                #if defined(_ShadowStrengthMaskLOD)
                    shadowStrengthMask = LIL_SAMPLE_2D(_ShadowStrengthMask, lil_sampler_linear_repeat, fd.uvMain);
                    if(_ShadowStrengthMaskLOD) shadowStrengthMask = LIL_SAMPLE_2D_GRAD(_ShadowStrengthMask, lil_sampler_linear_repeat, fd.uvMain, max(fd.ddxMain, _ShadowStrengthMaskLOD), max(fd.ddyMain, _ShadowStrengthMaskLOD));
                #else
                    shadowStrengthMask = LIL_SAMPLE_2D_GRAD(_ShadowStrengthMask, lil_sampler_linear_repeat, fd.uvMain, max(fd.ddxMain, _ShadowStrengthMaskLOD), max(fd.ddyMain, _ShadowStrengthMaskLOD));
                #endif
            #endif

            // Shade
            float aastrencth = _AAStrength;
            float4 lns = 1.0;
            if(_ShadowMaskType == 2)
            {
                float3 faceR = mul((float3x3)LIL_MATRIX_M, float3(1.0,0.0,0.0));
                float LdotR = dot(fd.L.xz, faceR.xz);
                float sdf = LdotR < 0 ? shadowStrengthMask.g : shadowStrengthMask.r;

                float3 faceF = mul((float3x3)LIL_MATRIX_M, float3(0.0,0.0,-1.0)).xyz;
                faceF.y *= _ShadowFlatBlur;
                faceF = dot(faceF,faceF) == 0 ? 0 : normalize(faceF);
                float3 faceL = fd.L.xyz;
                faceL.y *= _ShadowFlatBlur;
                faceL = dot(faceL,faceL) == 0 ? 0 : normalize(faceL);

                float lnSDF = dot(faceL,faceF);
                lns = saturate(lnSDF * 0.5 + sdf * 0.5 + 0.25);
                aastrencth = 0;
            }
            else
            {
                lns.x = saturate(dot(fd.L,N1)*0.5+0.5);
                lns.y = saturate(dot(fd.L,N2)*0.5+0.5);
                #if defined(LIL_FEATURE_SHADOW_3RD)
                    lns.z = saturate(dot(fd.L,N3)*0.5+0.5);
                #endif
            }

            // Shadow
            #if (defined(LIL_USE_SHADOW) || defined(LIL_LIGHTMODE_SHADOWMASK)) && defined(LIL_FEATURE_RECEIVE_SHADOW)
                float calculatedShadow = saturate(fd.attenuation + distance(fd.L, fd.origL));
                lns.x *= lerp(1.0, calculatedShadow, _ShadowReceive);
                lns.y *= lerp(1.0, calculatedShadow, _Shadow2ndReceive);
                #if defined(LIL_FEATURE_SHADOW_3RD)
                    lns.z *= lerp(1.0, calculatedShadow, _Shadow3rdReceive);
                #endif
            #endif

            // Blur Scale
            float shadowBlur = _ShadowBlur;
            float shadow2ndBlur = _Shadow2ndBlur;
            #if defined(LIL_FEATURE_SHADOW_3RD)
                float shadow3rdBlur = _Shadow3rdBlur;
            #endif
            #if defined(LIL_FEATURE_ShadowBlurMask)
                #if defined(_ShadowBlurMaskLOD)
                    float4 shadowBlurMask = LIL_SAMPLE_2D(_ShadowBlurMask, lil_sampler_linear_repeat, fd.uvMain);
                    if(_ShadowBlurMaskLOD) shadowBlurMask = LIL_SAMPLE_2D_GRAD(_ShadowBlurMask, lil_sampler_linear_repeat, fd.uvMain, max(fd.ddxMain, _ShadowBlurMaskLOD), max(fd.ddyMain, _ShadowBlurMaskLOD));
                #else
                    float4 shadowBlurMask = LIL_SAMPLE_2D_GRAD(_ShadowBlurMask, lil_sampler_linear_repeat, fd.uvMain, max(fd.ddxMain, _ShadowBlurMaskLOD), max(fd.ddyMain, _ShadowBlurMaskLOD));
                #endif
                shadowBlur *= shadowBlurMask.r;
                shadow2ndBlur *= shadowBlurMask.g;
                #if defined(LIL_FEATURE_SHADOW_3RD)
                    shadow3rdBlur *= shadowBlurMask.b;
                #endif
            #endif

            // AO Map & Toon
            #if defined(LIL_FEATURE_ShadowBorderMask)
                #if defined(_ShadowBorderMaskLOD)
                    float4 shadowBorderMask = LIL_SAMPLE_2D(_ShadowBorderMask, lil_sampler_linear_repeat, fd.uvMain);
                    if(_ShadowBorderMaskLOD) shadowBorderMask = LIL_SAMPLE_2D_GRAD(_ShadowBorderMask, lil_sampler_linear_repeat, fd.uvMain, max(fd.ddxMain, _ShadowBorderMaskLOD), max(fd.ddyMain, _ShadowBorderMaskLOD));
                #else
                    float4 shadowBorderMask = LIL_SAMPLE_2D_GRAD(_ShadowBorderMask, lil_sampler_linear_repeat, fd.uvMain, max(fd.ddxMain, _ShadowBorderMaskLOD), max(fd.ddyMain, _ShadowBorderMaskLOD));
                #endif
                shadowBorderMask.r = saturate(shadowBorderMask.r * _ShadowAOShift.x + _ShadowAOShift.y);
                shadowBorderMask.g = saturate(shadowBorderMask.g * _ShadowAOShift.z + _ShadowAOShift.w);
                #if defined(LIL_FEATURE_SHADOW_3RD)
                    shadowBorderMask.b = saturate(shadowBorderMask.b * _ShadowAOShift2.x + _ShadowAOShift2.y);
                #endif
                lns.xyz = _ShadowPostAO ? lns.xyz : lns.xyz * shadowBorderMask.rgb;

                lns.w = lns.x;
                lns.x = lilTooningNoSaturateScale(aastrencth, lns.x, _ShadowBorder, shadowBlur);
                lns.y = lilTooningNoSaturateScale(aastrencth, lns.y, _Shadow2ndBorder, shadow2ndBlur);
                lns.w = lilTooningNoSaturateScale(aastrencth, lns.w, _ShadowBorder, shadowBlur, _ShadowBorderRange);
                #if defined(LIL_FEATURE_SHADOW_3RD)
                    lns.z = lilTooningNoSaturateScale(aastrencth, lns.z, _Shadow3rdBorder, shadow3rdBlur);
                #endif
                lns = _ShadowPostAO ? lns * shadowBorderMask.rgbr : lns;
                lns = saturate(lns);
            #else
                lns.w = lns.x;
                lns.x = lilTooningScale(aastrencth, lns.x, _ShadowBorder, shadowBlur);
                lns.y = lilTooningScale(aastrencth, lns.y, _Shadow2ndBorder, shadow2ndBlur);
                lns.w = lilTooningScale(aastrencth, lns.w, _ShadowBorder, shadowBlur, _ShadowBorderRange);
                #if defined(LIL_FEATURE_SHADOW_3RD)
                    lns.z = lilTooningScale(aastrencth, lns.z, _Shadow3rdBorder, shadow3rdBlur);
                #endif
            #endif

            // Force shadow on back face
            float bfshadow = (fd.facing < 0.0) ? 1.0 - _BackfaceForceShadow : 1.0;
            lns.x *= bfshadow;
            lns.y *= bfshadow;
            lns.w *= bfshadow;
            #if defined(LIL_FEATURE_SHADOW_3RD)
                lns.z *= bfshadow;
            #endif

            // Copy
            fd.shadowmix = lns.x;
            // Strength
            float shadowStrength = _ShadowStrength;
            #ifdef LIL_COLORSPACE_GAMMA
                shadowStrength = lilSRGBToLinear(shadowStrength);
            #endif
            if(_ShadowMaskType == 1)
            {
                float3 flatN = normalize(mul((float3x3)LIL_MATRIX_M, float3(0.0,0.25,1.0)));//normalize(LIL_MATRIX_M._m02_m12_m22);
                float lnFlat = saturate((dot(flatN, fd.L) + _ShadowFlatBorder) / _ShadowFlatBlur);
                #if (defined(LIL_USE_SHADOW) || defined(LIL_LIGHTMODE_SHADOWMASK)) && defined(LIL_FEATURE_RECEIVE_SHADOW)
                    lnFlat *= lerp(1.0, calculatedShadow, _ShadowReceive);
                #endif
                float strengthValue = shadowStrengthMask.r;
                if (_CustomUseMsdfMaskShadow == 1) strengthValue = lilMSDF(shadowStrengthMask.rgb) * shadowStrengthMask.a;
                if (_CustomUseMsdfMaskShadow == 2) strengthValue = 1.0 - lilMSDF(shadowStrengthMask.rgb) * shadowStrengthMask.a;
                lns = lerp(lnFlat, lns, strengthValue);
            }
            else if(_ShadowMaskType == 0)
            {
                shadowStrength *= shadowStrengthMask.r;
            }
            lns.x = lerp(1.0, lns.x, shadowStrength);

            // Shadow Colors
            float4 shadowColorTex = 0.0;
            float4 shadow2ndColorTex = 0.0;
            float4 shadow3rdColorTex = 0.0;
            #if defined(LIL_FEATURE_SHADOW_LUT)
                if(_ShadowColorType == 1)
                {
                    float4 uvShadow;
                    float factor;
                    lilCalcLUTUV(fd.albedo, 16, 1, uvShadow, factor);
                    #if defined(LIL_FEATURE_ShadowColorTex)
                        shadowColorTex = lilSampleLUT(uvShadow, factor, _ShadowColorTex);
                    #endif
                    #if defined(LIL_FEATURE_Shadow2ndColorTex)
                        shadow2ndColorTex = lilSampleLUT(uvShadow, factor, _Shadow2ndColorTex);
                    #endif
                    #if defined(LIL_FEATURE_SHADOW_3RD) && defined(LIL_FEATURE_Shadow3rdColorTex)
                        shadow3rdColorTex = lilSampleLUT(uvShadow, factor, _Shadow3rdColorTex);
                    #endif
                }
                else
            #endif
            {
                #if defined(LIL_FEATURE_ShadowColorTex)
                    shadowColorTex = LIL_SAMPLE_2D(_ShadowColorTex, samp, fd.uvMain);
                #endif
                #if defined(LIL_FEATURE_Shadow2ndColorTex)
                    shadow2ndColorTex = LIL_SAMPLE_2D(_Shadow2ndColorTex, samp, fd.uvMain);
                #endif
                #if defined(LIL_FEATURE_SHADOW_3RD) && defined(LIL_FEATURE_Shadow3rdColorTex)
                    shadow3rdColorTex = LIL_SAMPLE_2D(_Shadow3rdColorTex, samp, fd.uvMain);
                #endif
            }

            // Shadow Color 1
            float3 indirectCol = lerp(fd.albedo, shadowColorTex.rgb, shadowColorTex.a) * _ShadowColor.rgb;

            // Shadow Color 2
            shadow2ndColorTex.rgb = lerp(fd.albedo, shadow2ndColorTex.rgb, shadow2ndColorTex.a) * _Shadow2ndColor.rgb;
            lns.y = _Shadow2ndColor.a - lns.y * _Shadow2ndColor.a;
            indirectCol = lerp(indirectCol, shadow2ndColorTex.rgb, lns.y);

            #if defined(LIL_FEATURE_SHADOW_3RD)
                // Shadow Color 3
                shadow3rdColorTex.rgb = lerp(fd.albedo, shadow3rdColorTex.rgb, shadow3rdColorTex.a) * _Shadow3rdColor.rgb;
                lns.z = _Shadow3rdColor.a - lns.z * _Shadow3rdColor.a;
                indirectCol = lerp(indirectCol, shadow3rdColorTex.rgb, lns.z);
            #endif

            // Multiply Main Color
            indirectCol = lerp(indirectCol, indirectCol*fd.albedo, _ShadowMainStrength);

            // Apply Light
            float3 directCol = fd.albedo * fd.lightColor;
            indirectCol = indirectCol * fd.lightColor;

            #if !defined(LIL_PASS_FORWARDADD)
                // Environment Light
                indirectCol = lerp(indirectCol, fd.albedo, fd.indLightColor);
            #endif
            // Fix
            indirectCol = min(indirectCol, directCol);
            // Gradation
            indirectCol = lerp(indirectCol, directCol, lns.w * _ShadowBorderColor.rgb);

            // Mix
            fd.col.rgb = lerp(indirectCol, directCol, lns.x);
        }
        else
        {
            fd.col.rgb *= fd.lightColor;
        }
    }
#else
    #undef OVERRIDE_SHADOW
#endif

// MatCap
#if defined(LIL_FEATURE_MATCAP)
    void lilGetMatCapMsdfMask(inout lilFragData fd LIL_SAMP_IN_FUNC(samp))
    {
        if(_UseMatCap)
        {
            // Normal
            float3 N = fd.matcapN;
            #if defined(LIL_FEATURE_NORMAL_1ST) || defined(LIL_FEATURE_NORMAL_2ND)
                N = lerp(fd.origN, fd.matcapN, _MatCapNormalStrength);
            #endif
            #if defined(LIL_FEATURE_MatCapBumpMap)
                if(_MatCapCustomNormal)
                {
                    float4 normalTex = LIL_SAMPLE_2D_ST(_MatCapBumpMap, samp, fd.uvMain);
                    float3 normalmap = lilUnpackNormalScale(normalTex, _MatCapBumpScale);
                    N = normalize(mul(normalmap, fd.TBN));
                    N = fd.facing < (_FlipNormal-1.0) ? -N : N;
                }
            #endif

            // UV
            float2 matUV = lilCalcMatCapUV(fd.uv1, normalize(N), fd.V, fd.headV, _MatCapTex_ST, _MatCapBlendUV1.xy, _MatCapZRotCancel, _MatCapPerspective, _MatCapVRParallaxStrength);

            // Color
            float4 matCapColor = _MatCapColor;
            #if defined(LIL_FEATURE_MatCapTex)
                matCapColor *= LIL_SAMPLE_2D_LOD(_MatCapTex, lil_sampler_linear_repeat, matUV, _MatCapLod);
            #endif
            #if !defined(LIL_PASS_FORWARDADD)
                matCapColor.rgb = lerp(matCapColor.rgb, matCapColor.rgb * fd.lightColor, _MatCapEnableLighting);
                matCapColor.a = lerp(matCapColor.a, matCapColor.a * fd.shadowmix, _MatCapShadowMask);
            #else
                if(_MatCapBlendMode < 3) matCapColor.rgb *= fd.lightColor * _MatCapEnableLighting;
                matCapColor.a = lerp(matCapColor.a, matCapColor.a * fd.shadowmix, _MatCapShadowMask);
            #endif
            #if LIL_RENDER == 2 && !defined(LIL_REFRACTION)
                if(_MatCapApplyTransparency) matCapColor.a *= fd.col.a;
            #endif
            matCapColor.a = fd.facing < (_MatCapBackfaceMask-1.0) ? 0.0 : matCapColor.a;
            float3 matCapMask = 1.0;
            #if defined(LIL_FEATURE_MatCapBlendMask)
                // MSDF Mask Process
                float4 maskColor = LIL_SAMPLE_2D_ST(_MatCapBlendMask, samp, fd.uvMain);
                float3 maskValue = maskColor.rgb;
                if (_CustomUseMsdfMaskMatCap1 == 1) maskValue = lilMSDF(maskColor.rgb) * maskColor.a;
                if (_CustomUseMsdfMaskMatCap1 == 2) maskValue = 1.0 - lilMSDF(maskColor.rgb) * maskColor.a;
                matCapMask = maskValue;
            #endif

            // Blend
            matCapColor.rgb = lerp(matCapColor.rgb, matCapColor.rgb * fd.albedo, _MatCapMainStrength);
            fd.col.rgb = lilBlendColor(fd.col.rgb, matCapColor.rgb, _MatCapBlend * matCapColor.a * matCapMask, _MatCapBlendMode);
        }
    }
#else
    #undef OVERRIDE_MATCAP
#endif

// MatCap 2nd
#if defined(LIL_FEATURE_MATCAP2ND)
    void lilGetMatCap2ndMsdfMask(inout lilFragData fd LIL_SAMP_IN_FUNC(samp))
    {
        if(_UseMatCap2nd)
        {
            // Normal
            float3 N = fd.matcap2ndN;
            #if defined(LIL_FEATURE_NORMAL_1ST) || defined(LIL_FEATURE_NORMAL_2ND)
                N = lerp(fd.origN, fd.matcap2ndN, _MatCap2ndNormalStrength);
            #endif
            #if defined(LIL_FEATURE_MatCap2ndBumpMap)
                if(_MatCap2ndCustomNormal)
                {
                    float4 normalTex = LIL_SAMPLE_2D_ST(_MatCap2ndBumpMap, samp, fd.uvMain);
                    float3 normalmap = lilUnpackNormalScale(normalTex, _MatCap2ndBumpScale);
                    N = normalize(mul(normalmap, fd.TBN));
                    N = fd.facing < (_FlipNormal-1.0) ? -N : N;
                }
            #endif

            // UV
            float2 mat2ndUV = lilCalcMatCapUV(fd.uv1, N, fd.V, fd.headV, _MatCap2ndTex_ST, _MatCap2ndBlendUV1.xy, _MatCap2ndZRotCancel, _MatCap2ndPerspective, _MatCap2ndVRParallaxStrength);

            // Color
            float4 matCap2ndColor = _MatCap2ndColor;
            #if defined(LIL_FEATURE_MatCap2ndTex)
                matCap2ndColor *= LIL_SAMPLE_2D_LOD(_MatCap2ndTex, lil_sampler_linear_repeat, mat2ndUV, _MatCap2ndLod);
            #endif
            #if !defined(LIL_PASS_FORWARDADD)
                matCap2ndColor.rgb = lerp(matCap2ndColor.rgb, matCap2ndColor.rgb * fd.lightColor, _MatCap2ndEnableLighting);
                matCap2ndColor.a = lerp(matCap2ndColor.a, matCap2ndColor.a * fd.shadowmix, _MatCap2ndShadowMask);
            #else
                if(_MatCap2ndBlendMode < 3) matCap2ndColor.rgb *= fd.lightColor * _MatCap2ndEnableLighting;
                matCap2ndColor.a = lerp(matCap2ndColor.a, matCap2ndColor.a * fd.shadowmix, _MatCap2ndShadowMask);
            #endif
            #if LIL_RENDER == 2 && !defined(LIL_REFRACTION)
                if(_MatCap2ndApplyTransparency) matCap2ndColor.a *= fd.col.a;
            #endif
            matCap2ndColor.a = fd.facing < (_MatCap2ndBackfaceMask-1.0) ? 0.0 : matCap2ndColor.a;
            float3 matCapMask = 1.0;
            #if defined(LIL_FEATURE_MatCap2ndBlendMask)
                // MSDF Mask Process
                float4 maskColor = LIL_SAMPLE_2D_ST(_MatCap2ndBlendMask, samp, fd.uvMain);
                float3 maskValue = maskColor.rgb;
                if (_CustomUseMsdfMaskMatCap2 == 1) maskValue = lilMSDF(maskColor.rgb) * maskColor.a;
                if (_CustomUseMsdfMaskMatCap2 == 2) maskValue = 1.0 - lilMSDF(maskColor.rgb) * maskColor.a;
                matCapMask = maskValue;
            #endif

            // Blend
            matCap2ndColor.rgb = lerp(matCap2ndColor.rgb, matCap2ndColor.rgb * fd.albedo, _MatCap2ndMainStrength);
            fd.col.rgb = lilBlendColor(fd.col.rgb, matCap2ndColor.rgb, _MatCap2ndBlend * matCap2ndColor.a * matCapMask, _MatCap2ndBlendMode);
        }
    }
#else
    #undef OVERRIDE_MATCAP2ND
#endif

// Emission
#if defined(LIL_FEATURE_EMISSION_1ST)
    void lilEmissionMsdfMask(inout lilFragData fd LIL_SAMP_IN_FUNC(samp))
    {
        if(_UseEmission)
        {
            float4 emissionColor = _EmissionColor;
            // UV
            float2 emissionUV = fd.uv0;
            if(_EmissionMap_UVMode == 1) emissionUV = fd.uv1;
            if(_EmissionMap_UVMode == 2) emissionUV = fd.uv2;
            if(_EmissionMap_UVMode == 3) emissionUV = fd.uv3;
            if(_EmissionMap_UVMode == 4) emissionUV = fd.uvRim;
            //if(_EmissionMap_UVMode == 4) emissionUV = fd.uvPanorama;
            float2 _EmissionMapParaTex = emissionUV + _EmissionParallaxDepth * fd.parallaxOffset;
            // Texture
            #if defined(LIL_FEATURE_EmissionMap)
                #if defined(LIL_FEATURE_ANIMATE_EMISSION_UV)
                    emissionColor *= LIL_GET_EMITEX(_EmissionMap, _EmissionMapParaTex);
                #else
                    emissionColor *= LIL_SAMPLE_2D_ST(_EmissionMap, sampler_EmissionMap, _EmissionMapParaTex);
                #endif
            #endif
            // Mask
            #if defined(LIL_FEATURE_EmissionBlendMask)
                // MSDF Mask Process
                #if defined(LIL_FEATURE_ANIMATE_EMISSION_MASK_UV)
                    float4 maskColor = LIL_GET_EMIMASK(_EmissionBlendMask, fd.uv0);
                #else
                    float4 maskColor = LIL_SAMPLE_2D_ST(_EmissionBlendMask, samp, fd.uvMain);
                #endif
                float4 maskValue = maskColor.rgba;
                if (_CustomUseMsdfMaskEmission1 == 1) maskValue = float4((lilMSDF(maskColor.rgb) * maskColor.a).xxx, 1.0);
                if (_CustomUseMsdfMaskEmission1 == 2) maskValue = float4((1.0 - lilMSDF(maskColor.rgb) * maskColor.a).xxx, 1.0);
                emissionColor *= maskValue;
            #endif
            // Gradation
            #if defined(LIL_FEATURE_EmissionGradTex)
                #if defined(LIL_FEATURE_EMISSION_GRADATION) && defined(LIL_FEATURE_AUDIOLINK)
                    if(_EmissionUseGrad)
                    {
                        float gradUV = _EmissionGradSpeed * LIL_TIME + fd.audioLinkValue * _AudioLink2EmissionGrad;
                        emissionColor *= LIL_SAMPLE_1D_LOD(_EmissionGradTex, lil_sampler_linear_repeat, gradUV, 0);
                    }
                #elif defined(LIL_FEATURE_EMISSION_GRADATION)
                    if(_EmissionUseGrad) emissionColor *= LIL_SAMPLE_1D(_EmissionGradTex, lil_sampler_linear_repeat, _EmissionGradSpeed * LIL_TIME);
                #endif
            #endif
            #if defined(LIL_FEATURE_AUDIOLINK)
                if(_AudioLink2Emission) emissionColor.a *= fd.audioLinkValue;
            #endif
            emissionColor.rgb = lerp(emissionColor.rgb, emissionColor.rgb * fd.invLighting, _EmissionFluorescence);
            emissionColor.rgb = lerp(emissionColor.rgb, emissionColor.rgb * fd.albedo, _EmissionMainStrength);
            float emissionBlend = _EmissionBlend * lilCalcBlink(_EmissionBlink) * emissionColor.a;
            #if LIL_RENDER == 2 && !defined(LIL_REFRACTION)
                emissionBlend *= fd.col.a;
            #endif
            fd.col.rgb = lilBlendColor(fd.col.rgb, emissionColor.rgb, emissionBlend, _EmissionBlendMode);
        }
    }
#else
    #undef OVERRIDE_EMISSION_1ST
#endif

// Emission 2nd
#if defined(LIL_FEATURE_EMISSION_2ND)
    void lilEmission2ndMsdfMask(inout lilFragData fd LIL_SAMP_IN_FUNC(samp))
    {
        if(_UseEmission2nd)
        {
            float4 emission2ndColor = _Emission2ndColor;
            // UV
            float2 emission2ndUV = fd.uv0;
            if(_Emission2ndMap_UVMode == 1) emission2ndUV = fd.uv1;
            if(_Emission2ndMap_UVMode == 2) emission2ndUV = fd.uv2;
            if(_Emission2ndMap_UVMode == 3) emission2ndUV = fd.uv3;
            if(_Emission2ndMap_UVMode == 4) emission2ndUV = fd.uvRim;
            //if(_Emission2ndMap_UVMode == 4) emission2ndUV = fd.uvPanorama;
            float2 _Emission2ndMapParaTex = emission2ndUV + _Emission2ndParallaxDepth * fd.parallaxOffset;
            // Texture
            #if defined(LIL_FEATURE_Emission2ndMap)
                #if defined(LIL_FEATURE_ANIMATE_EMISSION_UV)
                    emission2ndColor *= LIL_GET_EMITEX(_Emission2ndMap, _Emission2ndMapParaTex);
                #else
                    emission2ndColor *= LIL_SAMPLE_2D_ST(_Emission2ndMap, sampler_Emission2ndMap, _Emission2ndMapParaTex);
                #endif
            #endif
            // Mask
            #if defined(LIL_FEATURE_Emission2ndBlendMask)
                // MSDF Mask Process
                #if defined(LIL_FEATURE_ANIMATE_EMISSION_MASK_UV)
                    float4 maskColor = LIL_GET_EMIMASK(_Emission2ndBlendMask, fd.uv0);
                #else
                    float4 maskColor = LIL_SAMPLE_2D_ST(_Emission2ndBlendMask, samp, fd.uvMain);
                #endif
                float4 maskValue = maskColor.rgba;
                if (_CustomUseMsdfMaskEmission2 == 1) maskValue = float4((lilMSDF(maskColor.rgb) * maskColor.a).xxx, 1.0);
                if (_CustomUseMsdfMaskEmission2 == 2) maskValue = float4((1.0 - lilMSDF(maskColor.rgb) * maskColor.a).xxx, 1.0);
                emission2ndColor *= maskValue;
            #endif
            // Gradation
            #if defined(LIL_FEATURE_Emission2ndGradTex)
                #if defined(LIL_FEATURE_EMISSION_GRADATION) && defined(LIL_FEATURE_AUDIOLINK)
                    if(_Emission2ndUseGrad)
                    {
                        float gradUV = _Emission2ndGradSpeed * LIL_TIME + fd.audioLinkValue * _AudioLink2Emission2ndGrad;
                        emission2ndColor *= LIL_SAMPLE_1D_LOD(_Emission2ndGradTex, lil_sampler_linear_repeat, gradUV, 0);
                    }
                #elif defined(LIL_FEATURE_EMISSION_GRADATION)
                    if(_Emission2ndUseGrad) emission2ndColor *= LIL_SAMPLE_1D(_Emission2ndGradTex, lil_sampler_linear_repeat, _Emission2ndGradSpeed * LIL_TIME);
                #endif
            #endif
            #if defined(LIL_FEATURE_AUDIOLINK)
                if(_AudioLink2Emission2nd) emission2ndColor.a *= fd.audioLinkValue;
            #endif
            emission2ndColor.rgb = lerp(emission2ndColor.rgb, emission2ndColor.rgb * fd.invLighting, _Emission2ndFluorescence);
            emission2ndColor.rgb = lerp(emission2ndColor.rgb, emission2ndColor.rgb * fd.albedo, _Emission2ndMainStrength);
            float emission2ndBlend = _Emission2ndBlend * lilCalcBlink(_Emission2ndBlink) * emission2ndColor.a;
            #if LIL_RENDER == 2 && !defined(LIL_REFRACTION)
                emission2ndBlend *= fd.col.a;
            #endif
            fd.col.rgb = lilBlendColor(fd.col.rgb, emission2ndColor.rgb, emission2ndBlend, _Emission2ndBlendMode);
        }
    }
#else
    #undef OVERRIDE_EMISSION_2ND
#endif
