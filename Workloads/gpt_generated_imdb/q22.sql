WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
        COUNT(DISTINCT mc.company_id) AS distinct_company_count,
        COUNT(DISTINCT kw.keyword) AS distinct_keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword kw ON kw.id = mk.keyword_id
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    kind,
    COUNT(*) AS movie_count,
    AVG(distinct_cast_count) AS avg_cast_per_movie,
    AVG(distinct_company_count) AS avg_companies_per_movie,
    AVG(distinct_keyword_count) AS avg_keywords_per_movie,
    MIN(production_year) AS earliest_year,
    MAX(production_year) AS latest_year
FROM movie_cast_counts
WHERE production_year IS NOT NULL
GROUP BY kind
ORDER BY movie_count DESC
