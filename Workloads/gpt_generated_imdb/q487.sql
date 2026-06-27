WITH movie_details AS (
    SELECT
        cn.name AS company_name,
        ct.kind AS company_type,
        kt.kind AS movie_kind,
        t.id AS movie_id,
        t.production_year,
        mi.info_type_id,
        mi.info
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    JOIN title t
        ON mc.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
)
SELECT
    md.company_name,
    md.company_type,
    md.movie_kind,
    COUNT(DISTINCT md.movie_id) AS total_movies,
    COUNT(DISTINCT CASE WHEN md.info_type_id = 101 THEN md.movie_id END) AS movies_with_runtime,
    AVG(md.production_year) AS avg_production_year,
    MIN(md.production_year) AS earliest_year,
    MAX(md.production_year) AS latest_year
FROM movie_details md
WHERE md.production_year >= 2000
GROUP BY md.company_name, md.company_type, md.movie_kind
ORDER BY total_movies DESC
LIMIT 10
