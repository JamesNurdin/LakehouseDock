/*
  Aggregated movie statistics by production year and kind (e.g., movie, TV series).
  For each year/kind we count the number of titles, total and average number of
  distinct cast members, production companies, and keywords.
*/
WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN name n ON ci.person_id = n.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_company_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id
),
movie_keyword_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id
)
SELECT
    mc.production_year,
    mc.kind,
    COUNT(*) AS num_movies,
    SUM(mc.cast_count) AS total_cast,
    AVG(mc.cast_count) AS avg_cast_per_movie,
    SUM(co.company_count) AS total_companies,
    AVG(co.company_count) AS avg_companies_per_movie,
    SUM(kw.keyword_count) AS total_keywords,
    AVG(kw.keyword_count) AS avg_keywords_per_movie
FROM movie_cast_counts mc
JOIN movie_company_counts co ON co.movie_id = mc.movie_id
JOIN movie_keyword_counts kw ON kw.movie_id = mc.movie_id
WHERE mc.production_year IS NOT NULL
GROUP BY mc.production_year, mc.kind
ORDER BY mc.production_year, mc.kind
