WITH rating_agg AS (
    SELECT
        movie_id,
        SUM(CASE WHEN info_type_id = 1 THEN note ELSE 0 END) AS total_rating_note,
        COUNT(CASE WHEN info_type_id = 1 THEN 1 END) AS rating_count
    FROM movie_info_idx
    GROUP BY movie_id
),
keyword_agg AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword_id) AS distinct_keyword_count
    FROM movie_keyword
    GROUP BY movie_id
)
SELECT
    kt.kind,
    COUNT(t.id) AS title_count,
    AVG(t.production_year) AS avg_production_year,
    COALESCE(SUM(ka.distinct_keyword_count), 0) AS total_distinct_keywords,
    COALESCE(SUM(ra.total_rating_note), 0) AS total_rating_note,
    COALESCE(SUM(ra.rating_count), 0) AS total_rating_count,
    CASE WHEN SUM(ra.rating_count) > 0 THEN SUM(ra.total_rating_note) / SUM(ra.rating_count) ELSE NULL END AS avg_rating_note
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN rating_agg ra ON ra.movie_id = t.id
LEFT JOIN keyword_agg ka ON ka.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY kt.kind
ORDER BY title_count DESC
