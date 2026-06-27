WITH cast_per_movie AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_per_movie AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
info_per_movie AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS info_count
    FROM movie_info_idx mi
    GROUP BY mi.movie_id
)
SELECT
    kt.kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(COALESCE(cpm.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(kpm.keyword_count, 0)) AS avg_keyword_per_movie,
    AVG(COALESCE(ipm.info_count, 0)) AS avg_info_entries_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_per_movie cpm ON t.id = cpm.movie_id
LEFT JOIN keyword_per_movie kpm ON t.id = kpm.movie_id
LEFT JOIN info_per_movie ipm ON t.id = ipm.movie_id
WHERE t.production_year >= 2000
GROUP BY kt.kind, t.production_year
ORDER BY movie_count DESC
LIMIT 20
