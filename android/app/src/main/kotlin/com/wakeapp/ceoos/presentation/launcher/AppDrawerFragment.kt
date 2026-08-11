package com.wakeapp.ceoos.presentation.launcher

import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.wakeapp.ceoos.R
import kotlinx.coroutines.launch
import kotlin.math.max

class AppDrawerFragment : Fragment(R.layout.fragment_app_drawer) {
    private lateinit var recyclerView: RecyclerView
    private lateinit var adapter: AppIconAdapter

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val host = requireActivity() as HomeActivity
        recyclerView = view.findViewById(R.id.drawer_recycler)
        adapter = AppIconAdapter(host.homeViewModel::onAppClicked)

        recyclerView.apply {
            layoutManager = GridLayoutManager(requireContext(), calculateSpanCount())
            adapter = this@AppDrawerFragment.adapter
            itemAnimator = null
        }

        view.findViewById<TextView>(R.id.drawer_close).setOnClickListener {
            host.closeDrawer()
        }

        view.findViewById<View>(R.id.drawer_root).setOnClickListener {
            host.closeDrawer()
        }

        lifecycleScope.launch {
            repeatOnLifecycle(androidx.lifecycle.Lifecycle.State.STARTED) {
                host.homeViewModel.uiState.collect { state ->
                    adapter.submitList(state.apps)
                }
            }
        }
    }

    private fun calculateSpanCount(): Int {
        val widthDp = resources.configuration.screenWidthDp
        return max(4, widthDp / 88)
    }
}
