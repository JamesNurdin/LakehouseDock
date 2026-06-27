WITH per_movie AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS genre,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN mc.company_id END) AS prod_company_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'distribution' THEN mc.company_id END) AS dist_company_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM title t
    LEFT JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN company_type ct
        ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN keyword k
        ON mk.keyword_id = k.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    pm.production_year,
    pm.genre,
    COUNT(*) AS num_movies,
    SUM(pm.cast_count) AS total_cast_members,
    AVG(pm.cast_count) AS avg_cast_per_movie,
    SUM(pm.prod_company_count) AS total_production_companies,
    SUM(pm.dist_company_count) AS total_distribution_companies,
    ARRAY_AGG(DISTINCT kw) AS top_keywords
FROM per_movie pm
LEFT JOIN UNNEST(pm.keywords) AS t(kw) ON TRUE
GROUP BY pm.production_year, pm.genre
ORDER BY pm.production_year, pm.genre
