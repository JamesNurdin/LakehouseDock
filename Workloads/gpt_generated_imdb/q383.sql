/*
  Analytical overview of feature‑film production by year.
  For each production year we compute:
    • Total number of movies (kind = 'movie')
    • Average runtime (info_type_id = 201)
    • Average user rating (info_type_id = 101)
    • Count of distinct keywords associated with the movies
    • Count of distinct actors appearing in the movies
  The query follows the allowed join rules and uses only the listed tables.
*/
WITH movie_titles AS (
    SELECT t.id AS title_id,
           t.production_year AS production_year
    FROM title t
    JOIN kind_type kt ON kt.id = t.kind_id
    WHERE kt.kind = 'movie'
),
movies_per_year AS (
    SELECT mt.production_year AS production_year,
           COUNT(*) AS total_movies
    FROM movie_titles mt
    GROUP BY mt.production_year
),
avg_runtime_per_year AS (
    SELECT mt.production_year AS production_year,
           AVG(CAST(mi.info AS DOUBLE)) AS avg_runtime
    FROM movie_titles mt
    JOIN movie_info mi ON mi.movie_id = mt.title_id
    WHERE mi.info_type_id = 201
    GROUP BY mt.production_year
),
avg_rating_per_year AS (
    SELECT mt.production_year AS production_year,
           AVG(CAST(mi.info AS DOUBLE)) AS avg_rating
    FROM movie_titles mt
    JOIN movie_info mi ON mi.movie_id = mt.title_id
    WHERE mi.info_type_id = 101
    GROUP BY mt.production_year
),
keyword_count_per_year AS (
    SELECT mt.production_year AS production_year,
           COUNT(DISTINCT mk.keyword_id) AS distinct_keywords
    FROM movie_titles mt
    JOIN movie_keyword mk ON mk.movie_id = mt.title_id
    GROUP BY mt.production_year
),
actor_count_per_year AS (
    SELECT mt.production_year AS production_year,
           COUNT(DISTINCT n.id) AS distinct_actors
    FROM movie_titles mt
    JOIN cast_info ci ON ci.movie_id = mt.title_id
    JOIN name n ON n.id = ci.person_id
    GROUP BY mt.production_year
)
SELECT
    mp.production_year,
    mp.total_movies,
    ar.avg_rating,
    rt.avg_runtime,
    kc.distinct_keywords,
    ac.distinct_actors
FROM movies_per_year mp
LEFT JOIN avg_rating_per_year ar ON ar.production_year = mp.production_year
LEFT JOIN avg_runtime_per_year rt ON rt.production_year = mp.production_year
LEFT JOIN keyword_count_per_year kc ON kc.production_year = mp.production_year
LEFT JOIN actor_count_per_year ac ON ac.production_year = mp.production_year
ORDER BY mp.production_year
