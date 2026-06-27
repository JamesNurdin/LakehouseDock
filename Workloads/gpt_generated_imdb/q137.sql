/*
  Analytical query: for movies released from the year 2000 onward, compute per‑kind statistics
  – total number of movies
  – average number of cast members per movie
  – average number of keywords per movie
  – average number of companies per movie
*/
WITH movie_metrics AS (
    SELECT
        t.id               AS movie_id,
        t.title,
        t.production_year,
        kt.kind            AS kind,
        COUNT(DISTINCT ci.person_id)   AS cast_count,
        COUNT(DISTINCT mk.keyword_id)  AS keyword_count,
        COUNT(DISTINCT mc.company_id)  AS company_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN keyword k
        ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    kind,
    COUNT(*)                         AS movie_count,
    AVG(cast_count)                  AS avg_cast_per_movie,
    AVG(keyword_count)               AS avg_keywords_per_movie,
    AVG(company_count)               AS avg_companies_per_movie
FROM movie_metrics
GROUP BY kind
ORDER BY movie_count DESC
