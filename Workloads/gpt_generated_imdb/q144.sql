WITH info_summary AS (
    SELECT
        it.info AS info_type,
        COUNT(*) AS total_info_entries,
        COUNT(DISTINCT mi.movie_id) AS distinct_movies,
        AVG(mi.note) AS avg_note
    FROM movie_info_idx mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY it.info
),
top_movie_per_info AS (
    SELECT
        t.title,
        it.info AS info_type,
        mi.note,
        ROW_NUMBER() OVER (PARTITION BY it.info ORDER BY mi.note DESC) AS note_rank
    FROM movie_info_idx mi
    JOIN title t ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE t.production_year >= 2000
)
SELECT
    isum.info_type,
    isum.total_info_entries,
    isum.distinct_movies,
    isum.avg_note,
    tmp.title AS top_movie,
    tmp.note AS top_movie_note
FROM info_summary isum
LEFT JOIN (
    SELECT *
    FROM top_movie_per_info
    WHERE note_rank = 1
) tmp ON isum.info_type = tmp.info_type
ORDER BY isum.total_info_entries DESC
LIMIT 20
