WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
production_countries AS (
    SELECT DISTINCT
        mc.movie_id,
        cn.country_code
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production'
      AND cn.country_code IS NOT NULL
)
SELECT
    pc.country_code,
    COUNT(DISTINCT pc.movie_id) AS num_movies,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
    SUM(COALESCE(cc.cast_count, 0)) AS total_cast_members,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
    SUM(COALESCE(kc.keyword_count, 0)) AS total_keywords,
    MIN(t.production_year) AS earliest_production_year,
    MAX(t.production_year) AS latest_production_year
FROM production_countries pc
JOIN title t ON pc.movie_id = t.id
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
WHERE t.production_year BETWEEN 2000 AND 2020
  AND kt.kind = 'movie'
GROUP BY pc.country_code
ORDER BY num_movies DESC
LIMIT 20
