WITH
    movie_ratings AS (
        SELECT
            t.id AS movie_id,
            CAST(mi.info AS double) AS rating
        FROM title t
        JOIN kind_type kt ON t.kind_id = kt.id
        JOIN movie_info mi ON mi.movie_id = t.id
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE kt.kind = 'movie'
          AND t.production_year >= 2000
          AND it.info = 'rating'
    ),
    movie_cast_counts AS (
        SELECT
            t.id AS movie_id,
            COUNT(DISTINCT ci.person_id) AS cast_count
        FROM title t
        JOIN kind_type kt ON t.kind_id = kt.id
        JOIN cast_info ci ON ci.movie_id = t.id
        WHERE kt.kind = 'movie'
          AND t.production_year >= 2000
        GROUP BY t.id
    ),
    movie_filtered AS (
        SELECT
            mr.movie_id,
            mr.rating,
            mc.cast_count
        FROM movie_ratings mr
        JOIN movie_cast_counts mc ON mc.movie_id = mr.movie_id
        WHERE mc.cast_count >= 10
    ),
    company_ratings AS (
        SELECT
            cn.name AS company_name,
            mf.rating
        FROM movie_filtered mf
        JOIN movie_companies mco ON mco.movie_id = mf.movie_id
        JOIN company_type ct ON mco.company_type_id = ct.id
        JOIN company_name cn ON mco.company_id = cn.id
        WHERE ct.kind = 'production company'
    )
SELECT
    cr.company_name,
    COUNT(*) AS movie_count,
    AVG(cr.rating) AS avg_rating
FROM company_ratings cr
GROUP BY cr.company_name
HAVING COUNT(*) >= 5
ORDER BY avg_rating DESC
LIMIT 10
