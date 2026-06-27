WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_member_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_info_counts AS (
    SELECT
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM movie_info mi
    GROUP BY mi.movie_id
),
movie_info_idx_counts AS (
    SELECT
        mi_idx.movie_id,
        COUNT(DISTINCT mi_idx.info_type_id) AS info_idx_type_count
    FROM movie_info_idx mi_idx
    GROUP BY mi_idx.movie_id
)
SELECT
    kt.kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(COALESCE(mcc.cast_member_count, 0)) AS avg_cast_members,
    AVG(COALESCE(mic.info_type_count, 0)) AS avg_info_type_count,
    AVG(COALESCE(mii.info_idx_type_count, 0)) AS avg_info_idx_type_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_cast_counts mcc ON mcc.movie_id = t.id
LEFT JOIN movie_info_counts mic ON mic.movie_id = t.id
LEFT JOIN movie_info_idx_counts mii ON mii.movie_id = t.id
WHERE kt.kind = 'movie'
  AND t.production_year >= 2000
GROUP BY kt.kind, t.production_year
ORDER BY kt.kind, t.production_year DESC
