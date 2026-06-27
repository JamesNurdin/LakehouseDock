WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_company_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN cn.id END) AS production_company_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'distribution' THEN cn.id END) AS distribution_company_count
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name cn ON cn.id = mc.company_id
    JOIN company_type ct ON ct.id = mc.company_type_id
    GROUP BY t.id
)
SELECT
    mc.production_year,
    mc.kind,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    AVG(mc.cast_count) AS avg_cast_per_movie,
    AVG(mco.company_count) AS avg_companies_per_movie,
    AVG(mco.production_company_count) AS avg_production_companies_per_movie,
    AVG(mco.distribution_company_count) AS avg_distribution_companies_per_movie
FROM movie_cast_counts mc
JOIN movie_company_counts mco ON mco.movie_id = mc.movie_id
WHERE mc.production_year IS NOT NULL
GROUP BY mc.production_year, mc.kind
ORDER BY mc.production_year DESC, mc.kind
