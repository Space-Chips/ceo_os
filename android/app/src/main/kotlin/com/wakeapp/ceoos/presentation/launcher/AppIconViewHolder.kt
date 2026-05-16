package com.wakeapp.ceoos.presentation.launcher

import android.content.ComponentName
import android.content.pm.PackageManager
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.wakeapp.ceoos.R
import com.wakeapp.ceoos.presentation.launcher.icon.IconBitmapCache
import com.wakeapp.ceoos.presentation.launcher.icon.IconGrayFilter
import com.wakeapp.ceoos.presentation.launcher.model.LaunchableAppItem

class AppIconViewHolder(
    itemView: View,
) : RecyclerView.ViewHolder(itemView) {
    private val iconView: ImageView = itemView.findViewById(R.id.app_icon)
    private val labelView: TextView = itemView.findViewById(R.id.app_label)

    fun bind(
        item: LaunchableAppItem,
        packageManager: PackageManager,
        onAppClicked: (LaunchableAppItem) -> Unit,
    ) {
        labelView.text = item.label
        labelView.alpha = if (item.blocked) 0.68f else 1f
        iconView.alpha = if (item.blocked) 0.68f else 1f

        val cacheKey = "${item.packageName}/${item.activityName}/${item.blocked}"
        val cached = IconBitmapCache.get(cacheKey)
        if (cached != null) {
            iconView.setImageDrawable(cached)
        } else {
            val baseDrawable = try {
                packageManager.getActivityIcon(ComponentName(item.packageName, item.activityName))
            } catch (_: Exception) {
                try {
                    packageManager.getApplicationIcon(item.packageName)
                } catch (_: Exception) {
                    null
                }
            }
            if (baseDrawable != null) {
                val finalDrawable = if (item.blocked) {
                    IconGrayFilter.toGrayscale(baseDrawable, itemView.context)
                } else {
                    baseDrawable.constantState?.newDrawable()?.mutate() ?: baseDrawable
                }
                IconBitmapCache.put(cacheKey, finalDrawable)
                iconView.setImageDrawable(finalDrawable)
            } else {
                iconView.setImageDrawable(null)
            }
        }

        itemView.setOnClickListener { onAppClicked(item) }
    }
}
