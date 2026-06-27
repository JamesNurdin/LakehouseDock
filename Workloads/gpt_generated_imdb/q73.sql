-- Analytical view per production year and title kind
-- Shows number of movies, average cast size, average number of production companies,
-- and total distinct actors involved in that year‑kind combination.
WITH movie_base AS (
    SELECT t.id AS movie_id,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt
      ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
cast_agg AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS distinct_actor_cnt,
           COUNT(*)                     AS total_cast_entries
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_agg AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS distinct_company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
year_kind_actors AS (
    SELECT t.production_year,
           kt.kind,
           COUNT(DISTINCT ci.person_id) AS distinct_actors
    FROM cast_info ci
    JOIN title t
      ON ci.movie_id = t.id
    JOIN kind_type kt
      ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind
)
SELECT mb.production_year,
       mb.kind,
       COUNT(DISTINCT mb.movie_id)               AS num_movies,
       AVG(COALESCE(ca.distinct_actor_cnt, 0))   AS avg_distinct_actors_per_movie,
       AVG(COALESCE(ca.total_cast_entries, 0))   AS avg_cast_entries_per_movie,
       AVG(COALESCE(co.distinct_company_cnt, 0)) AS avg_distinct_companies_per_movie,
       yak.distinct_actors                       AS total_distinct_actors_in_year_kind
FROM movie_base mb
LEFT JOIN cast_agg ca
  ON mb.movie_id = ca.movie_id
LEFT JOIN company_agg co
  ON mb.movie_id = co.movie_id
LEFT JOIN year_kind_actors yak
  ON mb.production_year = yak.production_year
 AND mb.kind = yak.kind
GROUP BY mb.production_year, mb.kind, yak.distinct_actors
ORDER BY mb.production_year, mb.kind
