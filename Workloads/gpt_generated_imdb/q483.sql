WITH movie_aggregates AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.kind AS genre,
        COALESCE(c.cast_cnt, 0) AS cast_cnt,
        COALESCE(kws.keyword_cnt, 0) AS keyword_cnt,
        COALESCE(comp.company_cnt, 0) AS company_cnt
    FROM title t
    JOIN kind_type k ON t.kind_id = k.id
    LEFT JOIN (
        SELECT movie_id, COUNT(*) AS cast_cnt
        FROM cast_info
        GROUP BY movie_id
    ) c ON c.movie_id = t.id
    LEFT JOIN (
        SELECT movie_id, COUNT(*) AS keyword_cnt
        FROM movie_keyword
        GROUP BY movie_id
    ) kws ON kws.movie_id = t.id
    LEFT JOIN (
        SELECT movie_id, COUNT(DISTINCT company_id) AS company_cnt
        FROM movie_companies
        GROUP BY movie_id
    ) comp ON comp.movie_id = t.id
)
SELECT
    genre,
    production_year,
    COUNT(*) AS movie_count,
    SUM(cast_cnt) AS total_cast,
    AVG(cast_cnt) AS avg_cast_per_movie,
    SUM(keyword_cnt) AS total_keywords,
    AVG(keyword_cnt) AS avg_keywords_per_movie,
    SUM(company_cnt) AS total_companies,
    AVG(company_cnt) AS avg_companies_per_movie
FROM movie_aggregates
WHERE production_year >= 2000
GROUP BY genre, production_year
ORDER BY genre, production_year
