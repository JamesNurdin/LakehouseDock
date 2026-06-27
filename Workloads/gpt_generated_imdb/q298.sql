WITH title_agg AS (
    SELECT
        title.kind_id,
        COUNT(*) AS title_cnt,
        AVG(title.production_year) AS avg_prod_year
    FROM title
    GROUP BY title.kind_id
),
company_agg AS (
    SELECT
        title.kind_id,
        COUNT(DISTINCT movie_companies.company_id) AS distinct_company_cnt
    FROM title
    JOIN movie_companies
        ON movie_companies.movie_id = title.id
    GROUP BY title.kind_id
),
keyword_agg AS (
    SELECT
        title.kind_id,
        COUNT(DISTINCT movie_keyword.keyword_id) AS distinct_keyword_cnt
    FROM title
    JOIN movie_keyword
        ON movie_keyword.movie_id = title.id
    GROUP BY title.kind_id
),
info_length_agg AS (
    SELECT
        title.kind_id,
        AVG(LENGTH(movie_info.info)) AS avg_info_length
    FROM title
    JOIN movie_info
        ON movie_info.movie_id = title.id
    WHERE movie_info.info_type_id = 3
    GROUP BY title.kind_id
),
info_idx_agg AS (
    SELECT
        title.kind_id,
        AVG(movie_info_idx.note) AS avg_note
    FROM title
    JOIN movie_info_idx
        ON movie_info_idx.movie_id = title.id
    WHERE movie_info_idx.info_type_id = 3
    GROUP BY title.kind_id
)
SELECT
    kind_type.kind AS kind,
    title_agg.title_cnt,
    title_agg.avg_prod_year,
    company_agg.distinct_company_cnt,
    keyword_agg.distinct_keyword_cnt,
    info_length_agg.avg_info_length,
    info_idx_agg.avg_note
FROM kind_type
LEFT JOIN title_agg
    ON title_agg.kind_id = kind_type.id
LEFT JOIN company_agg
    ON company_agg.kind_id = kind_type.id
LEFT JOIN keyword_agg
    ON keyword_agg.kind_id = kind_type.id
LEFT JOIN info_length_agg
    ON info_length_agg.kind_id = kind_type.id
LEFT JOIN info_idx_agg
    ON info_idx_agg.kind_id = kind_type.id
ORDER BY title_agg.title_cnt DESC
LIMIT 10
