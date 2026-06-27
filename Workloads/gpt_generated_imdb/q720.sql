WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS comp_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_cnt,
    AVG(COALESCE(cc.cast_cnt, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(kc.kw_cnt, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(compc.comp_cnt, 0)) AS avg_companies_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN company_counts compc ON compc.movie_id = t.id
WHERE kt.kind = 'movie'
  AND t.production_year IS NOT NULL
GROUP BY t.production_year
ORDER BY t.production_year
