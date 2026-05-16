package com.wakeapp.ceoos.presentation.launcher.icon

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable

object IconGrayFilter {
    fun toGrayscale(drawable: Drawable, context: Context): Drawable {
        val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 96
        val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 96
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val workingDrawable = drawable.constantState?.newDrawable()?.mutate() ?: drawable.mutate()
        workingDrawable.setBounds(0, 0, width, height)
        workingDrawable.draw(canvas)

        val grayscaleBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val grayscaleCanvas = Canvas(grayscaleBitmap)
        val colorMatrix = ColorMatrix().apply { setSaturation(0f) }
        val alphaMatrix = ColorMatrix(
            floatArrayOf(
                1f, 0f, 0f, 0f, 0f,
                0f, 1f, 0f, 0f, 0f,
                0f, 0f, 1f, 0f, 0f,
                0f, 0f, 0f, 0.62f, 0f,
            ),
        )
        colorMatrix.postConcat(alphaMatrix)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            colorFilter = ColorMatrixColorFilter(colorMatrix)
        }
        grayscaleCanvas.drawBitmap(bitmap, 0f, 0f, paint)
        return BitmapDrawable(context.resources, grayscaleBitmap).apply {
            alpha = (255 * 0.68f).toInt()
        }
    }
}
