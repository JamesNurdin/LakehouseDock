WITH info_counts AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type_name,
        mi.info AS info_value,
        COUNT(DISTINCT mi.movie_id) AS movie_count,
        AVG(mi.note) AS avg_note
    FROM movie_info_idx mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE mi.note IS NOT NULL
    GROUP BY it.id, it.info, mi.info
),
ranked_info AS (
    SELECT
        info_type_id,
        info_type_name,
        info_value,
        movie_count,
        avg_note,
        ROW_NUMBER() OVER (PARTITION BY info_type_id ORDER BY movie_count DESC) AS rank_within_type
    FROM info_counts
)
SELECT
    info_type_id,
    info_type_name,
    info_value,
    movie_count,
    avg_note
FROM ranked_info
WHERE rank_within_type <= 3
ORDER BY info_type_id, rank_within_type
