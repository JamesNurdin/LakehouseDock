WITH kind_stats AS (
    SELECT
        kind_type.kind,
        COUNT(DISTINCT title.id) AS title_cnt,
        AVG(title.production_year) AS avg_production_year,
        COUNT(DISTINCT movie_companies.company_id) AS distinct_company_cnt,
        COUNT(DISTINCT movie_keyword.keyword_id) AS distinct_keyword_cnt
    FROM title
    JOIN kind_type ON title.kind_id = kind_type.id
    LEFT JOIN movie_companies ON movie_companies.movie_id = title.id
    LEFT JOIN movie_keyword ON movie_keyword.movie_id = title.id
    WHERE title.production_year >= 2000
    GROUP BY kind_type.kind
)
SELECT
    kind,
    title_cnt,
    avg_production_year,
    distinct_company_cnt,
    distinct_keyword_cnt,
    RANK() OVER (ORDER BY title_cnt DESC) AS title_rank
FROM kind_stats
ORDER BY title_cnt DESC
