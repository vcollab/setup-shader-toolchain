// The smallest source that exercises all three tools: slangc emits SPIR-V from
// it, spirv-cross turns that into GLSL ES 3.00, and glslang type-checks the
// result. It deliberately computes something trivial — the point is that the
// chain runs, not what it produces.

[shader("vertex")]
float4 vertexMain(float2 a_position : POSITION) : SV_Position
{
    return float4(a_position, 0.0, 1.0);
}

[shader("fragment")]
float4 fragmentMain(float4 pos : SV_Position) : SV_Target
{
    return float4(pos.xy, 0.0, 1.0);
}
