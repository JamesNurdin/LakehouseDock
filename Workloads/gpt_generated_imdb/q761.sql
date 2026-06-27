WITH movies_filtered AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2000
),

cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS total_cast,
           COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN movies_filtered mf ON ci.movie_id = mf.movie_id
    GROUP BY ci.movie_id
),

company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN movies_filtered mf ON mc.movie_id = mf.movie_id
    GROUP BY mc.movie_id
),

rating_runtime AS (
    SELECT mi.movie_id,
           AVG(TRY_CAST(mi.info AS DOUBLE)) FILTER (WHERE it.info = 'rating') AS avg_rating,
           AVG(TRY_CAST(mi.info AS DOUBLE)) FILTER (WHERE it.info = 'runtime') AS avg_runtime
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    JOIN movies_filtered mf ON mi.movie_id = mf.movie_id
    GROUP BY mi.movie_id
)

SELECT mf.title,
       mf.production_year,
       COALESCE(cc.total_cast, 0) AS total_cast,
       COALESCE(cc.female_cast, 0) AS female_cast,
       COALESCE(compc.company_count, 0) AS company_count,
       rr.avg_rating,
       rr.avg_runtime
FROM movies_filtered mf
LEFT JOIN cast_counts cc ON mf.movie_id = cc.movie_id
LEFT JOIN company_counts compc ON mf.movie_id = compc.movie_id
LEFT JOIN rating_runtime rr ON mf.movie_id = rr.movie_id
ORDER BY total_cast DESC
LIMIT 10
