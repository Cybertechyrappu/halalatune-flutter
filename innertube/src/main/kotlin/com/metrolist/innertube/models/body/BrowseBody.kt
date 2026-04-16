package com.halalatune.innertube.models.body

import com.halalatune.innertube.models.Context
import com.halalatune.innertube.models.Continuation
import kotlinx.serialization.Serializable

@Serializable
data class BrowseBody(
    val context: Context,
    val browseId: String?,
    val params: String?,
    val continuation: String?
)
