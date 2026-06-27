WITH info_counts AS (
    SELECT
        it.info AS info_type,
        mi.info AS movie_info,
        COUNT(*) AS cnt,
        AVG(mi.note) AS avg_note
    FROM movie_info_idx mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE mi.note IS NOT NULL
    GROUP BY it.info, mi.info
),
ranked_info AS (
    SELECT
        info_type,
        movie_info,
        cnt,
        avg_note,
        ROW_NUMBER() OVER (PARTITION BY info_type ORDER BY cnt DESC) AS rn
    FROM info_counts
)
SELECT
    info_type,
    movie_info,
    cnt,
    avg_note
FROM ranked_info
WHERE rn <= 3
ORDER BY info_type, cnt DESC
