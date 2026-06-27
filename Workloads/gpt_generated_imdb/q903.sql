WITH movies AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
),
rating AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(*) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT m.production_year,
       COUNT(DISTINCT m.movie_id) AS movie_count,
       AVG(r.rating) AS avg_rating,
       SUM(cc.cast_count) AS total_cast_members,
       SUM(compc.company_count) AS total_companies,
       SUM(kwc.keyword_count) AS total_keywords
FROM movies m
LEFT JOIN rating r ON r.movie_id = m.movie_id
LEFT JOIN cast_counts cc ON cc.movie_id = m.movie_id
LEFT JOIN company_counts compc ON compc.movie_id = m.movie_id
LEFT JOIN keyword_counts kwc ON kwc.movie_id = m.movie_id
GROUP BY m.production_year
ORDER BY m.production_year
