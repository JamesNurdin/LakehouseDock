WITH movie_cast AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind_name,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
      AND kt.kind = 'movie'
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_company AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN cn.id END) AS production_company_count
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
)
SELECT
    mc.title,
    mc.production_year,
    mc.cast_count,
    co.company_count,
    co.production_company_count
FROM movie_cast mc
JOIN movie_company co ON co.movie_id = mc.movie_id
ORDER BY mc.cast_count DESC
LIMIT 10
