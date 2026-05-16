package com.wakeapp.ceoos.presentation.launcher.icon

import android.graphics.drawable.Drawable
import android.util.LruCache

object IconBitmapCache {
    private val cache = object : LruCache<String, Drawable>(256) {}

    fun get(key: String): Drawable? = cache.get(key)

    fun put(key: String, drawable: Drawable) {
        cache.put(key, drawable)
    }

    fun clear() {
        cache.evictAll()
    }
}
