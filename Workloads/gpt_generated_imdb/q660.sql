WITH movie_metrics AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        mi.info_type_id,
        SUM(mi.note) AS total_note,
        AVG(mi.note) AS avg_note,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    LEFT JOIN movie_info_idx mi
        ON mi.movie_id = t.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, mi.info_type_id
),
info_agg AS (
    SELECT
        it.info AS info_type,
        COUNT(DISTINCT mm.title_id) AS movie_count,
        AVG(mm.total_note) AS avg_total_note,
        AVG(mm.keyword_count) AS avg_keyword_count
    FROM movie_metrics mm
    JOIN info_type it
        ON it.id = mm.info_type_id
    WHERE mm.total_note IS NOT NULL
    GROUP BY it.info
)
SELECT
    info_type,
    movie_count,
    avg_total_note,
    avg_keyword_count,
    RANK() OVER (ORDER BY avg_total_note DESC) AS info_type_rank
FROM info_agg
ORDER BY avg_total_note DESC
LIMIT 10
