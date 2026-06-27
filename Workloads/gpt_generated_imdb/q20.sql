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
movie_production_companies AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT cn.name) AS prod_company_count
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production company'
    GROUP BY t.id
)
SELECT
    mc.production_year,
    mc.kind,
    COUNT(*) AS num_movies,
    SUM(mc.cast_count) AS total_cast_members,
    AVG(mc.cast_count) AS avg_cast_per_movie,
    SUM(pc.prod_company_count) AS total_production_companies,
    AVG(pc.prod_company_count) AS avg_production_companies_per_movie
FROM movie_cast_counts mc
JOIN movie_production_companies pc ON pc.movie_id = mc.movie_id
WHERE mc.production_year BETWEEN 2000 AND 2020
GROUP BY mc.production_year, mc.kind
ORDER BY mc.production_year, mc.kind
