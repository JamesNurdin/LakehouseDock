WITH movie_budget_gross AS (
    SELECT
        mi.movie_id,
        MAX(CASE WHEN it.info = 'budget' THEN CAST(mi.info AS double) END) AS budget,
        MAX(CASE WHEN it.info = 'gross' THEN CAST(mi.info AS double) END) AS gross
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
),
movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production company'
    GROUP BY mc.movie_id
),
movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(bg.budget) AS avg_budget,
    AVG(bg.gross) AS avg_gross,
    AVG(cc.cast_count) AS avg_cast_size,
    AVG(pc.company_count) AS avg_production_companies,
    AVG(kc.keyword_count) AS avg_keywords_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_budget_gross bg ON bg.movie_id = t.id
LEFT JOIN movie_cast_counts cc ON cc.movie_id = t.id
LEFT JOIN movie_company_counts pc ON pc.movie_id = t.id
LEFT JOIN movie_keyword_counts kc ON kc.movie_id = t.id
WHERE t.production_year >= 2000
  AND kt.kind = 'movie'
GROUP BY t.production_year
ORDER BY t.production_year
