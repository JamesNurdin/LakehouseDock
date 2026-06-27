WITH movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        kt.kind,
        t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
),
cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
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
)
SELECT
    m.kind,
    COUNT(*) AS num_movies,
    SUM(COALESCE(cc.cast_count, 0)) AS total_cast_members,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
    SUM(COALESCE(compc.company_count, 0)) AS total_companies,
    AVG(COALESCE(compc.company_count, 0)) AS avg_companies_per_movie,
    SUM(COALESCE(kc.keyword_count, 0)) AS total_keywords,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
    MIN(m.production_year) AS earliest_production_year,
    MAX(m.production_year) AS latest_production_year
FROM movies m
LEFT JOIN cast_counts cc ON cc.movie_id = m.movie_id
LEFT JOIN company_counts compc ON compc.movie_id = m.movie_id
LEFT JOIN keyword_counts kc ON kc.movie_id = m.movie_id
GROUP BY m.kind
ORDER BY num_movies DESC
LIMIT 10
