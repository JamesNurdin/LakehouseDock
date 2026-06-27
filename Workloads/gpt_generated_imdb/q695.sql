WITH movies AS (
    SELECT
        t.id,
        t.production_year,
        kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
movie_counts AS (
    SELECT
        production_year,
        kind,
        COUNT(DISTINCT id) AS total_movies
    FROM movies
    GROUP BY production_year, kind
),
avg_ratings AS (
    SELECT
        t.production_year,
        kt.kind,
        AVG(CAST(mi.info AS double)) AS avg_rating
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_info mi ON t.id = mi.movie_id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY t.production_year, kt.kind
),
distinct_cast AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS distinct_cast
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.production_year, kt.kind
),
company_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        cn.name AS company_name,
        COUNT(DISTINCT t.id) AS movies_per_company
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY t.production_year, kt.kind, cn.name
),
top_company AS (
    SELECT
        production_year,
        kind,
        company_name,
        movies_per_company,
        ROW_NUMBER() OVER (PARTITION BY production_year, kind ORDER BY movies_per_company DESC) AS rn
    FROM company_counts
)
SELECT
    mc.production_year,
    mc.kind,
    mc.total_movies,
    ar.avg_rating,
    dc.distinct_cast,
    tc.company_name AS top_company,
    tc.movies_per_company AS top_company_movie_count
FROM movie_counts mc
LEFT JOIN avg_ratings ar
    ON mc.production_year = ar.production_year AND mc.kind = ar.kind
LEFT JOIN distinct_cast dc
    ON mc.production_year = dc.production_year AND mc.kind = dc.kind
LEFT JOIN top_company tc
    ON mc.production_year = tc.production_year AND mc.kind = tc.kind AND tc.rn = 1
ORDER BY mc.production_year DESC, mc.total_movies DESC
LIMIT 20
