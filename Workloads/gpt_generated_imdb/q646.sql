/*
  Analytical query: for each keyword and production year (2010+),
  count how many distinct movies are tagged with that keyword, and compute
  the average size of the cast and the average number of companies involved
  per movie. Results are ordered by the number of movies descending and
  limited to the top 20 keyword‑year combinations.
*/
WITH movie_cast AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_size
    FROM title t
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    GROUP BY t.id
),
movie_companies_agg AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    GROUP BY t.id
)
SELECT
    k.keyword,
    t.production_year,
    COUNT(DISTINCT mk.movie_id) AS num_movies,
    AVG(mc.cast_size) AS avg_cast_size,
    AVG(mco.company_count) AS avg_companies_per_movie
FROM keyword k
JOIN movie_keyword mk
    ON mk.keyword_id = k.id
JOIN title t
    ON mk.movie_id = t.id
LEFT JOIN movie_cast mc
    ON mc.movie_id = mk.movie_id
LEFT JOIN movie_companies_agg mco
    ON mco.movie_id = mk.movie_id
WHERE t.production_year >= 2010
GROUP BY k.keyword, t.production_year
ORDER BY num_movies DESC, t.production_year DESC
LIMIT 20
