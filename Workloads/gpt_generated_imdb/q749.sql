WITH company_movie_data AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        CAST(mi.info AS double) AS rating,
        kw.keyword AS keyword
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    JOIN title t
        ON mc.movie_id = t.id
    LEFT JOIN movie_info mi
        ON t.id = mi.movie_id
    LEFT JOIN info_type it
        ON mi.info_type_id = it.id
        AND it.info = 'rating'
    LEFT JOIN movie_keyword mk
        ON t.id = mk.movie_id
    LEFT JOIN keyword kw
        ON mk.keyword_id = kw.id
    WHERE ct.kind = 'production'
      AND t.production_year >= 2000
)
SELECT
    cmd.company_name,
    COUNT(DISTINCT cmd.movie_id) AS movie_count,
    ROUND(AVG(cmd.rating), 2) AS avg_rating,
    COUNT(DISTINCT cmd.keyword) AS distinct_keyword_count,
    array_join(array_agg(DISTINCT cmd.keyword), ', ') AS keywords
FROM company_movie_data cmd
WHERE cmd.rating IS NOT NULL
GROUP BY cmd.company_name
ORDER BY movie_count DESC, avg_rating DESC
LIMIT 10
