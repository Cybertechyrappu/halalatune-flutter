package com.halalatune.innertube.pages

import com.halalatune.innertube.models.Album
import com.halalatune.innertube.models.AlbumItem
import com.halalatune.innertube.models.Artist
import com.halalatune.innertube.models.ArtistItem
import com.halalatune.innertube.models.MusicResponsiveListItemRenderer
import com.halalatune.innertube.models.MusicTwoRowItemRenderer
import com.halalatune.innertube.models.PlaylistItem
import com.halalatune.innertube.models.SongItem
import com.halalatune.innertube.models.YTItem
import com.halalatune.innertube.models.oddElements
import com.halalatune.innertube.utils.parseTime

data class LibraryAlbumsPage(
    val albums: List<AlbumItem>,
    val continuation: String?,
) {
    companion object {
        fun fromMusicTwoRowItemRenderer(renderer: MusicTwoRowItemRenderer): AlbumItem? {
            return AlbumItem(
                        browseId = renderer.navigationEndpoint.browseEndpoint?.browseId ?: return null,
                        playlistId = renderer.thumbnailOverlay?.musicItemThumbnailOverlayRenderer?.content
                            ?.musicPlayButtonRenderer?.playNavigationEndpoint
                            ?.watchPlaylistEndpoint?.playlistId ?: return null,
                        title = renderer.title.runs?.firstOrNull()?.text ?: return null,
                        artists = null,
                        year = renderer.subtitle?.runs?.lastOrNull()?.text?.toIntOrNull(),
                        thumbnail = renderer.thumbnailRenderer.musicThumbnailRenderer?.getThumbnailUrl() ?: return null,
                        explicit = renderer.subtitleBadges?.find {
                            it.musicInlineBadgeRenderer?.icon?.iconType == "MUSIC_EXPLICIT_BADGE"
                        } != null
                    )
        }
    }
}
