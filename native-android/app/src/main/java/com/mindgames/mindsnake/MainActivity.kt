package com.mindgames.mindsnake
import android.app.Activity
import android.os.Bundle
import android.view.Gravity
import android.view.MotionEvent
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.graphics.Color
import android.opengl.GLSurfaceView
import kotlin.math.abs

class MainActivity : Activity() {
 private lateinit var gl: GLSurfaceView
 private lateinit var game: SnakeRenderer
 private lateinit var hud: TextView
 private var sx=0f
 private var sy=0f
 override fun onCreate(savedInstanceState: Bundle?) {
  super.onCreate(savedInstanceState)
  gl=GLSurfaceView(this).apply {
   setEGLContextClientVersion(3)
   preserveEGLContextOnPause=false
   game=SnakeRenderer(this@MainActivity)
   setRenderer(game)
   renderMode=GLSurfaceView.RENDERMODE_CONTINUOUSLY
  }
  val root=FrameLayout(this)
  root.addView(gl,FrameLayout.LayoutParams(-1,-1))
  hud=TextView(this).apply { setTextColor(Color.WHITE); textSize=16f; setPadding(20,24,12,12); text="MIND SNAKE • SWIPE TO START" }
  root.addView(hud,FrameLayout.LayoutParams(-1,-2,Gravity.TOP))
  hud.setOnClickListener { gl.queueEvent { game.togglePause() } }
  val pad=LinearLayout(this).apply { gravity=Gravity.CENTER; setPadding(8,8,8,20) }
  val dirs=listOf(-1 to 0,0 to -1,0 to 1,1 to 0)
  listOf("←","↑","↓","→").forEachIndexed { i,label ->
   pad.addView(Button(this).apply { text=label; setOnClickListener { val d=dirs[i]; gl.queueEvent { game.turn(d.first,d.second) } } },LinearLayout.LayoutParams(0,60,1f))
  }
  root.addView(pad,FrameLayout.LayoutParams(-1,-2,Gravity.BOTTOM))
  gl.setOnTouchListener { _,e ->
   when(e.actionMasked) {
    MotionEvent.ACTION_DOWN -> { sx=e.x; sy=e.y; true }
    MotionEvent.ACTION_UP -> {
     val dx=e.x-sx; val dy=e.y-sy
     if(maxOf(abs(dx),abs(dy))>22f) {
      val x=if(abs(dx)>abs(dy)) if(dx>0) 1 else -1 else 0
      val z=if(abs(dy)>=abs(dx)) if(dy>0) 1 else -1 else 0
      gl.queueEvent { game.turn(x,z) }
     }
     true
    }
    else -> true
   }
  }
  game.hud={s,b,o,state -> runOnUiThread { hud.text="SCORE "+s+"  BEST "+b+"  MIND "+(o*100).toInt()+"%  "+state } }
  setContentView(root)
 }
 override fun onPause(){ gl.onPause(); super.onPause() }
 override fun onResume(){ super.onResume(); gl.onResume() }
 override fun onDestroy(){ if(::gl.isInitialized) gl.onPause(); super.onDestroy() }
}
