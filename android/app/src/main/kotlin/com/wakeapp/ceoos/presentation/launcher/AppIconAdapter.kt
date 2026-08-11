package com.wakeapp.ceoos.presentation.launcher

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import com.wakeapp.ceoos.R
import com.wakeapp.ceoos.presentation.launcher.model.LaunchableAppItem

class AppIconAdapter(
    private val onAppClicked: (LaunchableAppItem) -> Unit,
) : ListAdapter<LaunchableAppItem, AppIconViewHolder>(DiffCallback) {
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): AppIconViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(
            R.layout.item_app_icon,
            parent,
            false,
        )
        return AppIconViewHolder(view)
    }

    override fun onBindViewHolder(holder: AppIconViewHolder, position: Int) {
        holder.bind(getItem(position), holder.itemView.context.packageManager, onAppClicked)
    }

    private object DiffCallback : DiffUtil.ItemCallback<LaunchableAppItem>() {
        override fun areItemsTheSame(
            oldItem: LaunchableAppItem,
            newItem: LaunchableAppItem,
        ): Boolean {
            return oldItem.packageName == newItem.packageName &&
                oldItem.activityName == newItem.activityName
        }

        override fun areContentsTheSame(
            oldItem: LaunchableAppItem,
            newItem: LaunchableAppItem,
        ): Boolean = oldItem == newItem
    }
}
