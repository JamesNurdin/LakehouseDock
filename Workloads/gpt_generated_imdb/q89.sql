/*
  Analytical query: For each genre (kind_type.kind) and production year (>= 2000),
  compute the number of movies associated with each keyword and the average
  number of distinct production companies per movie for those movies. Then rank
  the keywords within each genre‑year by the average company count and return the
  top 5 keywords per genre‑year.
*/
WITH movie_company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_stats AS (
    SELECT
        kt.kind AS genre,
        t.production_year AS year,
        k.keyword,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(mcc.company_count) AS avg_company_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_company_counts mcc ON mcc.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY kt.kind, t.production_year, k.keyword
),
ranked_keywords AS (
    SELECT
        genre,
        year,
        keyword,
        movie_count,
        avg_company_count,
        ROW_NUMBER() OVER (PARTITION BY genre, year ORDER BY avg_company_count DESC) AS rk
    FROM keyword_stats
)
SELECT
    genre,
    year,
    keyword,
    movie_count,
    avg_company_count
FROM ranked_keywords
WHERE rk <= 5
ORDER BY genre, year, rk
