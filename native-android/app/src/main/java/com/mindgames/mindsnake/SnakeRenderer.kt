package com.mindgames.mindsnake
import android.content.Context
import android.opengl.GLES30
import android.opengl.GLSurfaceView
import android.opengl.Matrix
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.ArrayDeque
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import kotlin.math.*

private data class Cell(val x:Int,val z:Int)
private enum class Phase { TITLE, PLAYING, PAUSED, GAME_OVER }
private enum class OrbType { CLARITY, IMPULSE, ECHO }

class SnakeRenderer(private val context:Context):GLSurfaceView.Renderer {
 var hud:((Int,Int,Float,String)->Unit)?=null
 private val body=ArrayDeque<Cell>()
 private val turns=ArrayDeque<Cell>()
 private val rng=java.util.Random()
 private var direction=Cell(1,0)
 private var phase=Phase.TITLE
 private var orb=Cell(5,4)
 private var orbType=OrbType.CLARITY
 private var echo=0f
 private var score=0
 private var best=context.getSharedPreferences("mind_snake",0).getInt("best",0)
 private var overload=0f
 private var boost=0f
 private var accumulator=0.0
 private var last=0L
 private var program=0
 private var cubeVao=0
 private var cubeVbo=0
 private var gridVao=0
 private var gridVbo=0
 private var cubeCount=0
 private var gridCount=0
 private val projection=FloatArray(16)
 private val view=FloatArray(16)
 private val model=FloatArray(16)
 private val mv=FloatArray(16)
 private val mvp=FloatArray(16)
 private var uMvp=0
 private var uModel=0
 private var uColor=0
 private var uFog=0
 private var uFogColor=0

 fun turn(x:Int,z:Int) {
  if(phase==Phase.TITLE || phase==Phase.GAME_OVER){ start(); return }
  if(phase!=Phase.PLAYING || (x==0 && z==0)) return
  val base=turns.peekLast()?:direction
  if(x == -base.x && z == -base.z) return
  if(turns.size<2) turns.addLast(Cell(x,z))
 }
 override fun onSurfaceCreated(gl:GL10?,config:EGLConfig?) {
  release()
  GLES30.glClearColor(.012f,.02f,.055f,1f)
  GLES30.glEnable(GLES30.GL_DEPTH_TEST)
  GLES30.glEnable(GLES30.GL_CULL_FACE)
  program=link(VS,FS)
  uMvp=GLES30.glGetUniformLocation(program,"uMvp")
  uModel=GLES30.glGetUniformLocation(program,"uModel")
  uColor=GLES30.glGetUniformLocation(program,"uColor")
  uFog=GLES30.glGetUniformLocation(program,"uFog")
  uFogColor=GLES30.glGetUniformLocation(program,"uFogColor")
  createMeshes()
  last=System.nanoTime()
 }
 override fun onSurfaceChanged(gl:GL10?,width:Int,height:Int) {
  GLES30.glViewport(0,0,max(1,width),max(1,height))
  Matrix.perspectiveM(projection,0,48f,max(1,width).toFloat()/max(1,height),.1f,80f)
 }
 override fun onDrawFrame(gl:GL10?) {
  val now=System.nanoTime()
  val dt=if(last==0L) 0.0 else ((now-last)/1e9).coerceIn(0.0,.05)
  last=now
  if(phase==Phase.PLAYING) {
   accumulator+=dt
   val tick=(.16f-boost).coerceAtLeast(.075f).toDouble()
   while(accumulator>=tick){ step(tick.toFloat()); accumulator-=tick }
  }
  GLES30.glClear(GLES30.GL_COLOR_BUFFER_BIT or GLES30.GL_DEPTH_BUFFER_BIT)
  Matrix.setLookAtM(view,0,0f,10.5f,13.5f,0f,0f,0f,0f,1f,0f)
  GLES30.glUseProgram(program)
  GLES30.glUniform1f(uFog,.018f+overload*.055f)
  GLES30.glUniform3f(uFogColor,.012f+overload*.05f,.02f,.055f)
  drawGrid()
  drawCell(orb,if(orbType==OrbType.CLARITY) floatArrayOf(.15f,.95f,.86f) else floatArrayOf(1f,.3f,.12f),.34f)
  var i=0
  for(c in body){ val f=i++.toFloat()/max(1,body.size); drawCell(c,floatArrayOf(.1f,.72f-f*.25f,.94f-f*.3f),.38f) }
  hud?.invoke(score,best,overload,phase.name)
 }
 private fun step(dt:Float) {
  if(turns.isNotEmpty()) direction=turns.removeFirst()
  val head=body.peekFirst()?:Cell(0,0)
  val next=Cell(head.x+direction.x,head.z+direction.z)
  if(abs(next.x)>9 || abs(next.z)>9 || body.contains(next)){ phase=Phase.GAME_OVER; return }
  body.addFirst(next)
  if(next==orb) {
   if(orbType==OrbType.CLARITY){ score+=10; overload=(overload-.22f).coerceAtLeast(0f) }
   else { score+=25; overload=(overload+.18f).coerceAtMost(1f); boost=.035f }
   if(score>best){ best=score; context.getSharedPreferences("mind_snake",0).edit().putInt("best",best).apply() }
   spawn()
  } else body.removeLast()
  overload=(overload+dt*.006f).coerceAtMost(1f)
  boost=(boost-dt*.04f).coerceAtLeast(0f)
  if(overload>.72f && orbType!=OrbType.ECHO && rng.nextFloat()<.012f){ orb=randomCell(); orbType=OrbType.ECHO; echo=.8f }
  if(orbType==OrbType.ECHO){ echo-=dt; if(echo<=0f) orbType=OrbType.IMPULSE }
 }
 private fun spawn(){ orb=randomCell(); orbType=if(rng.nextFloat()<.72f) OrbType.CLARITY else OrbType.IMPULSE }
 private fun randomCell():Cell { var c:Cell; do{ c=Cell(rng.nextInt(17)-8,rng.nextInt(17)-8) }while(body.contains(c)); return c }
 private fun start(){
  body.clear(); body.add(Cell(0,0)); body.add(Cell(-1,0)); body.add(Cell(-2,0))
  direction=Cell(1,0); turns.clear(); score=0; overload=0f; boost=0f; accumulator=0.0; spawn(); phase=Phase.PLAYING
 }
 private fun drawGrid(){
  GLES30.glBindVertexArray(gridVao)
  Matrix.setIdentityM(model,0); Matrix.multiplyMM(mv,0,view,0,model,0); Matrix.multiplyMM(mvp,0,projection,0,mv,0)
  GLES30.glUniformMatrix4fv(uMvp,1,false,mvp,0); GLES30.glUniformMatrix4fv(uModel,1,false,model,0)
  GLES30.glUniform3f(uColor,.07f,.17f,.26f); GLES30.glDrawArrays(GLES30.GL_LINES,0,gridCount); GLES30.glBindVertexArray(0)
 }
 private fun drawCell(c:Cell,color:FloatArray,size:Float){
  GLES30.glBindVertexArray(cubeVao)
  Matrix.setIdentityM(model,0); Matrix.translateM(model,0,c.x.toFloat(),.32f,c.z.toFloat()); Matrix.scaleM(model,0,size,size,size)
  Matrix.multiplyMM(mv,0,view,0,model,0); Matrix.multiplyMM(mvp,0,projection,0,mv,0)
  GLES30.glUniformMatrix4fv(uMvp,1,false,mvp,0); GLES30.glUniformMatrix4fv(uModel,1,false,model,0)
  GLES30.glUniform3f(uColor,color[0],color[1],color[2]); GLES30.glDrawArrays(GLES30.GL_TRIANGLES,0,cubeCount); GLES30.glBindVertexArray(0)
 }
 private fun createMeshes(){ val cube=Geometry.cube(); cubeCount=cube.size/6; cubeVao=upload(cube,true); val grid=Geometry.grid(); gridCount=grid.size/6; gridVao=upload(grid,false) }
 private fun upload(data:FloatArray,cube:Boolean):Int{
  val vao=IntArray(1); val vbo=IntArray(1); GLES30.glGenVertexArrays(1,vao,0); GLES30.glGenBuffers(1,vbo,0)
  if(cube) cubeVbo=vbo[0] else gridVbo=vbo[0]
  val fb=ByteBuffer.allocateDirect(data.size*4).order(ByteOrder.nativeOrder()).asFloatBuffer(); fb.put(data).position(0)
  GLES30.glBindVertexArray(vao[0]); GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER,vbo[0]); GLES30.glBufferData(GLES30.GL_ARRAY_BUFFER,data.size*4,fb,GLES30.GL_STATIC_DRAW)
  GLES30.glEnableVertexAttribArray(0); GLES30.glVertexAttribPointer(0,3,GLES30.GL_FLOAT,false,24,0)
  GLES30.glEnableVertexAttribArray(1); GLES30.glVertexAttribPointer(1,3,GLES30.GL_FLOAT,false,24,12); GLES30.glBindVertexArray(0)
  return vao[0]
 }
 private fun compile(type:Int,source:String):Int{
  val id=GLES30.glCreateShader(type); GLES30.glShaderSource(id,source); GLES30.glCompileShader(id)
  val ok=IntArray(1); GLES30.glGetShaderiv(id,GLES30.GL_COMPILE_STATUS,ok,0)
  if(ok[0]==0){ val log=GLES30.glGetShaderInfoLog(id); GLES30.glDeleteShader(id); throw IllegalStateException("GLSL compile: "+log) }; return id
 }
 private fun link(v:String,f:String):Int{
  val vs=compile(GLES30.GL_VERTEX_SHADER,v); val fs=compile(GLES30.GL_FRAGMENT_SHADER,f)
  val p=GLES30.glCreateProgram(); GLES30.glAttachShader(p,vs); GLES30.glAttachShader(p,fs); GLES30.glLinkProgram(p); GLES30.glDeleteShader(vs); GLES30.glDeleteShader(fs)
  val ok=IntArray(1); GLES30.glGetProgramiv(p,GLES30.GL_LINK_STATUS,ok,0)
  if(ok[0]==0){ val log=GLES30.glGetProgramInfoLog(p); GLES30.glDeleteProgram(p); throw IllegalStateException("GLSL link: "+log) }; return p
 }
 private fun release(){
  if(cubeVbo!=0) GLES30.glDeleteBuffers(1,intArrayOf(cubeVbo),0)
  if(gridVbo!=0) GLES30.glDeleteBuffers(1,intArrayOf(gridVbo),0)
  if(cubeVao!=0) GLES30.glDeleteVertexArrays(1,intArrayOf(cubeVao),0)
  if(gridVao!=0) GLES30.glDeleteVertexArrays(1,intArrayOf(gridVao),0)
  if(program!=0) GLES30.glDeleteProgram(program)
  cubeVbo=0; gridVbo=0; cubeVao=0; gridVao=0; program=0
 }
 companion object {
  private const val VS="""#version 300 es
precision highp float; layout(location=0) in vec3 aPosition; layout(location=1) in vec3 aNormal;
uniform mat4 uMvp; uniform mat4 uModel; out vec3 vNormal; out vec3 vWorld;
void main(){vec4 world=uModel*vec4(aPosition,1.0);vWorld=world.xyz;vNormal=mat3(uModel)*aNormal;gl_Position=uMvp*vec4(aPosition,1.0);}"""
  private const val FS="""#version 300 es
precision highp float; in vec3 vNormal; in vec3 vWorld; uniform vec3 uColor; uniform float uFog; uniform vec3 uFogColor; out vec4 fragColor;
void main(){float l=max(dot(normalize(vNormal),normalize(vec3(-.4,.8,.5))),.2);vec3 lit=uColor*(.35+l*.8);float d=length(vWorld-vec3(0.0,10.5,13.5));float fog=1.0-exp(-uFog*uFog*d*d);fragColor=vec4(mix(lit,uFogColor,clamp(fog,0.0,.92)),1.0);}"""
 }
}
private object Geometry {
 fun cube():FloatArray {
  val out=ArrayList<Float>(216)
  val faces=arrayOf(
   floatArrayOf(0f,0f,1f,-.5f,-.5f,.5f,.5f,-.5f,.5f,.5f,.5f,.5f,-.5f,.5f,.5f),
   floatArrayOf(0f,0f,-1f,.5f,-.5f,-.5f,-.5f,-.5f,-.5f,-.5f,.5f,-.5f,.5f,.5f,-.5f),
   floatArrayOf(1f,0f,0f,.5f,-.5f,.5f,.5f,-.5f,-.5f,.5f,.5f,-.5f,.5f,.5f,.5f),
   floatArrayOf(-1f,0f,0f,-.5f,-.5f,-.5f,-.5f,-.5f,.5f,-.5f,.5f,.5f,-.5f,.5f,-.5f),
   floatArrayOf(0f,1f,0f,-.5f,.5f,.5f,.5f,.5f,.5f,.5f,.5f,-.5f,-.5f,.5f,-.5f),
   floatArrayOf(0f,-1f,0f,-.5f,-.5f,-.5f,.5f,-.5f,-.5f,.5f,-.5f,.5f,-.5f,-.5f,.5f))
  for(f in faces) for(i in intArrayOf(0,1,2,0,2,3)){ for(k in 0..2) out.add(f[3+i*3+k]); for(k in 0..2) out.add(f[k]) }
  return out.toFloatArray()
 }
 fun grid():FloatArray {
  val a=ArrayList<Float>()
  for(i in -9..9){
   a.addAll(listOf(i.toFloat(),0f,-9f,0f,1f,0f,i.toFloat(),0f,9f,0f,1f,0f))
   a.addAll(listOf(-9f,0f,i.toFloat(),0f,1f,0f,9f,0f,i.toFloat(),0f,1f,0f))
  }
  return a.toFloatArray()
 }
}
