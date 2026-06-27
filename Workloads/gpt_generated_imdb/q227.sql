WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_info_counts AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS info_count
    FROM movie_info mi
    GROUP BY mi.movie_id
),
movie_info_idx_counts AS (
    SELECT
        mi_idx.movie_id,
        COUNT(*) AS info_idx_count
    FROM movie_info_idx mi_idx
    GROUP BY mi_idx.movie_id
)
SELECT
    t.production_year,
    kt.kind,
    COUNT(DISTINCT t.id) AS movie_cnt,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(cc.role_count, 0)) AS avg_roles_per_movie,
    AVG(COALESCE(compc.company_count, 0)) AS avg_companies_per_movie,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(mi.info_count, 0)) AS avg_info_entries_per_movie,
    AVG(COALESCE(mii.info_idx_count, 0)) AS avg_info_idx_entries_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_counts compc ON compc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN movie_info_counts mi ON mi.movie_id = t.id
LEFT JOIN movie_info_idx_counts mii ON mii.movie_id = t.id
WHERE kt.kind = 'movie'
  AND t.production_year >= 2000
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC
