package io.flutter.plugins.bubble

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import com.phamtruong.keeplink.R
import kotlin.math.abs
import kotlin.math.max

class BubbleManager(
    private val context: Context,
    private val windowManager: WindowManager,
    private val removeZoneManager: RemoveZoneManager,
    private val onSaveLink: () -> Unit,
    private val onRemove: () -> Unit,
) {
    private enum class Edge { LEFT, RIGHT }

    private val handler = Handler(Looper.getMainLooper())
    private val idleRunnable = Runnable { enterIdleState() }
    private var positionAnimator: ValueAnimator? = null
    private lateinit var bubbleView: LinearLayout
    private lateinit var bubbleIcon: ImageView
    private lateinit var saveAction: ImageView
    private lateinit var bubbleParams: WindowManager.LayoutParams
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var edge = Edge.LEFT
    private var isExpanded = false
    private var isBusy = false
    private var isIdle = false

    fun showBubble() {
        if (::bubbleView.isInitialized && bubbleView.isAttachedToWindow) return
        bubbleParams = createLayoutParams(Gravity.TOP or Gravity.START, 0, 300)
        bubbleView = LayoutInflater.from(context)
            .inflate(R.layout.bubble_layout, null) as LinearLayout
        bubbleIcon = bubbleView.findViewById(R.id.bubble_icon)
        saveAction = bubbleView.findViewById(R.id.bubble_save_action)
        configureActionDirection()
        setTouchListener()
        bubbleView.setOnTouchListener { _, event ->
            if (event.actionMasked == MotionEvent.ACTION_OUTSIDE) {
                if (isExpanded) {
                    collapseActions(scheduleIdleAfter = false, idleImmediatelyAfter = true)
                } else {
                    enterIdleState()
                }
            }
            false
        }
        saveAction.setOnClickListener {
            if (isBusy) return@setOnClickListener
            collapseActions(scheduleIdleAfter = false)
            setBusy(true)
            onSaveLink()
        }
        windowManager.addView(bubbleView, bubbleParams)
        bubbleView.post {
            snapToEdge()
            scheduleIdle()
        }
    }

    fun removeBubble() {
        cancelIdle()
        positionAnimator?.cancel()
        if (::bubbleView.isInitialized && bubbleView.isAttachedToWindow) {
            windowManager.removeView(bubbleView)
        }
    }

    fun setBusy(busy: Boolean) {
        isBusy = busy
        if (!::bubbleIcon.isInitialized) return
        if (busy) {
            cancelIdle()
            wakeBubble()
        }
        bubbleIcon.animate()
            .alpha(if (busy) busyAlpha else activeAlpha)
            .scaleX(if (busy) busyScale else activeScale)
            .scaleY(if (busy) busyScale else activeScale)
            .setDuration(shortAnimationMs)
            .start()
        if (!busy) scheduleIdle()
    }

    private fun setTouchListener() {
        bubbleIcon.setOnTouchListener(object : View.OnTouchListener {
            private var isMoving = false

            override fun onTouch(view: View, event: MotionEvent): Boolean {
                when (event.actionMasked) {
                    MotionEvent.ACTION_DOWN -> {
                        isMoving = false
                        cancelIdle()
                        wakeBubble()
                        initialX = bubbleParams.x
                        initialY = bubbleParams.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }

                    MotionEvent.ACTION_MOVE -> {
                        val dx = event.rawX - initialTouchX
                        val dy = event.rawY - initialTouchY
                        if (!isMoving && (abs(dx) > dragThreshold || abs(dy) > dragThreshold)) {
                            isMoving = true
                            collapseActions(scheduleIdleAfter = false)
                            removeZoneManager.show()
                        }
                        if (isMoving) {
                            bubbleParams.x = initialX + dx.toInt()
                            bubbleParams.y = max(0, initialY + dy.toInt())
                            updateLayout()
                            removeZoneManager.scaleIfNeeded(event.rawY)
                        }
                        return true
                    }

                    MotionEvent.ACTION_UP -> {
                        removeZoneManager.hide()
                        if (isMoving && removeZoneManager.isInRemoveZone(event.rawY)) {
                            removeBubble()
                            onRemove()
                        } else if (isMoving) {
                            snapToEdge()
                            scheduleIdle()
                        } else if (!isBusy) {
                            toggleActions()
                        }
                        return true
                    }

                    MotionEvent.ACTION_CANCEL -> {
                        removeZoneManager.hide()
                        if (isMoving) snapToEdge()
                        scheduleIdle()
                        return true
                    }
                }
                return false
            }
        })
    }

    private fun toggleActions() {
        if (isExpanded) collapseActions() else expandActions()
    }

    private fun expandActions() {
        cancelIdle()
        wakeBubble()
        configureActionDirection()
        isExpanded = true
        saveAction.apply {
            visibility = View.VISIBLE
            alpha = 0f
            rotation = if (edge == Edge.LEFT) -90f else 90f
            translationX = if (edge == Edge.LEFT) -actionSlidePx else actionSlidePx
            scaleX = actionHiddenScale
            scaleY = actionHiddenScale
            animate()
                .alpha(1f)
                .rotation(0f)
                .translationX(0f)
                .scaleX(1f)
                .scaleY(1f)
                .setDuration(actionShowMs)
                .start()
        }
    }

    private fun collapseActions(
        scheduleIdleAfter: Boolean = true,
        idleImmediatelyAfter: Boolean = false,
    ) {
        if (!isExpanded || !::saveAction.isInitialized) {
            if (scheduleIdleAfter) scheduleIdle()
            return
        }
        isExpanded = false
        saveAction.animate()
            .alpha(0f)
            .rotation(if (edge == Edge.LEFT) 75f else -75f)
            .translationX(if (edge == Edge.LEFT) -actionSlidePx else actionSlidePx)
            .scaleX(actionHiddenScale)
            .scaleY(actionHiddenScale)
            .setDuration(actionHideMs)
            .withEndAction {
                if (!isExpanded) {
                    saveAction.visibility = View.INVISIBLE
                    saveAction.rotation = 0f
                    saveAction.translationX = 0f
                    when {
                        idleImmediatelyAfter -> enterIdleState()
                        scheduleIdleAfter -> scheduleIdle()
                    }
                }
            }
            .start()
    }

    private fun configureActionDirection() {
        val desiredIndex = if (edge == Edge.LEFT) bubbleView.childCount - 1 else 0
        if (bubbleView.indexOfChild(saveAction) == desiredIndex) return

        val bubbleScreenX = if (::bubbleParams.isInitialized && bubbleView.isAttachedToWindow) {
            bubbleParams.x + bubbleIcon.left
        } else {
            null
        }
        bubbleView.removeView(saveAction)
        val layoutParams = saveAction.layoutParams as? LinearLayout.LayoutParams
            ?: LinearLayout.LayoutParams(actionSizePx, actionSizePx)
        layoutParams.width = actionSizePx
        layoutParams.height = actionSizePx
        if (edge == Edge.LEFT) {
            layoutParams.marginStart = actionSpacingPx
            layoutParams.marginEnd = 0
            bubbleView.addView(saveAction, bubbleView.childCount, layoutParams)
        } else {
            layoutParams.marginStart = 0
            layoutParams.marginEnd = actionSpacingPx
            bubbleView.addView(saveAction, 0, layoutParams)
        }
        if (bubbleScreenX != null) {
            val newBubbleOffset = bubbleView.paddingLeft +
                if (edge == Edge.RIGHT) actionExtentPx else 0
            bubbleParams.x = bubbleScreenX - newBubbleOffset
            updateLayout()
        }
    }

    private fun snapToEdge() {
        val screenWidth = context.resources.displayMetrics.widthPixels
        val bubbleCenterX = bubbleParams.x + bubbleIcon.left + bubbleIcon.width / 2
        edge = if (bubbleCenterX < screenWidth / 2) {
            Edge.LEFT
        } else {
            Edge.RIGHT
        }
        configureActionDirection()
        animateWindowX(collapsedEdgeX())
    }

    private fun collapsedEdgeX(): Int {
        return if (edge == Edge.LEFT) 0 else screenWidth - bubbleView.width
    }

    private fun idleEdgeX(): Int {
        val hiddenDistance = (bubbleIcon.width * idleHiddenFraction).toInt()
        return if (edge == Edge.LEFT) {
            -hiddenDistance
        } else {
            screenWidth - bubbleView.width + hiddenDistance
        }
    }

    private fun enterIdleState() {
        if (isExpanded || isBusy || !bubbleView.isAttachedToWindow) return
        isIdle = true
        bubbleIcon.animate()
            .alpha(idleAlpha)
            .scaleX(idleScale)
            .scaleY(idleScale)
            .setDuration(idleAnimationMs)
            .start()
        animateWindowX(idleEdgeX(), idleAnimationMs)
    }

    private fun wakeBubble() {
        cancelIdle()
        if (!isIdle && bubbleIcon.alpha == activeAlpha) return
        isIdle = false
        bubbleIcon.animate()
            .alpha(activeAlpha)
            .scaleX(activeScale)
            .scaleY(activeScale)
            .setDuration(shortAnimationMs)
            .start()
        animateWindowX(collapsedEdgeX())
    }

    private fun scheduleIdle() {
        cancelIdle()
        if (!isExpanded && !isBusy) handler.postDelayed(idleRunnable, idleDelayMs)
    }

    private fun cancelIdle() {
        handler.removeCallbacks(idleRunnable)
    }

    private fun animateWindowX(targetX: Int, duration: Long = edgeAnimationMs) {
        if (!bubbleView.isAttachedToWindow) return
        positionAnimator?.cancel()
        val startX = bubbleParams.x
        if (startX == targetX) return
        positionAnimator = ValueAnimator.ofInt(startX, targetX).apply {
            this.duration = duration
            addUpdateListener {
                bubbleParams.x = it.animatedValue as Int
                updateLayout()
            }
            start()
        }
    }

    private fun updateLayout() {
        if (::bubbleView.isInitialized && bubbleView.isAttachedToWindow) {
            windowManager.updateViewLayout(bubbleView, bubbleParams)
        }
    }

    private val screenWidth: Int
        get() = context.resources.displayMetrics.widthPixels

    private val actionSpacingPx: Int
        get() = (5 * context.resources.displayMetrics.density).toInt()

    private val actionSizePx: Int
        get() = (36 * context.resources.displayMetrics.density).toInt()

    private val actionExtentPx: Int
        get() = actionSizePx + actionSpacingPx

    private val actionSlidePx: Float
        get() = 10 * context.resources.displayMetrics.density

    private fun createLayoutParams(
        gravity: Int,
        x: Int,
        y: Int,
    ): WindowManager.LayoutParams = WindowManager.LayoutParams(
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.WRAP_CONTENT,
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        },
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
        PixelFormat.TRANSLUCENT,
    ).apply {
        this.gravity = gravity
        this.x = x
        this.y = y
    }

    companion object {
        private const val dragThreshold = 12
        private const val idleDelayMs = 2_600L
        private const val edgeAnimationMs = 210L
        private const val idleAnimationMs = 260L
        private const val shortAnimationMs = 160L
        private const val actionShowMs = 210L
        private const val actionHideMs = 150L
        private const val activeAlpha = 1f
        private const val idleAlpha = 0.42f
        private const val busyAlpha = 0.58f
        private const val activeScale = 1f
        private const val idleScale = 0.78f
        private const val busyScale = 0.9f
        private const val actionHiddenScale = 0.62f
        private const val idleHiddenFraction = 0.48f
    }
}
