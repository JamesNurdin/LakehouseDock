WITH cast_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
keyword_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
),
info_counts AS (
    SELECT movie_id,
           COUNT(*) AS info_count
    FROM movie_info
    GROUP BY movie_id
),
movie_companies_filtered AS (
    SELECT mc.movie_id,
           mc.company_id
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production company'
),
stats AS (
    SELECT
        kt.kind AS kind,
        t.production_year,
        COUNT(DISTINCT t.id) AS total_movies,
        AVG(cc.cast_count) AS avg_cast_count,
        AVG(kc.keyword_count) AS avg_keyword_count,
        AVG(ic.info_count) AS avg_info_entries,
        COUNT(DISTINCT mcf.company_id) AS distinct_production_companies
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_counts cc ON t.id = cc.movie_id
    LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
    LEFT JOIN info_counts ic ON t.id = ic.movie_id
    LEFT JOIN movie_companies_filtered mcf ON t.id = mcf.movie_id
    WHERE t.production_year IS NOT NULL
    GROUP BY kt.kind, t.production_year
)
SELECT
    kind,
    production_year,
    total_movies,
    avg_cast_count,
    avg_keyword_count,
    avg_info_entries,
    distinct_production_companies,
    RANK() OVER (PARTITION BY kind ORDER BY total_movies DESC) AS rank_by_total_movies
FROM stats
ORDER BY total_movies DESC
LIMIT 20
