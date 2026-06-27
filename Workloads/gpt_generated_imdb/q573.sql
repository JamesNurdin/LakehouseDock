WITH base_titles AS (
    SELECT
        title.id AS title_id,
        title.kind_id,
        kind_type.kind,
        title.production_year
    FROM title
    JOIN kind_type
        ON title.kind_id = kind_type.id
    WHERE title.production_year >= 2000
),

titles_agg AS (
    SELECT
        kind_id,
        kind,
        COUNT(*) AS title_count,
        AVG(production_year) AS avg_production_year
    FROM base_titles
    GROUP BY kind_id, kind
),

companies_agg AS (
    SELECT
        base.kind_id,
        base.kind,
        COUNT(DISTINCT movie_companies.company_id) AS distinct_company_count
    FROM base_titles AS base
    JOIN movie_companies
        ON movie_companies.movie_id = base.title_id
    GROUP BY base.kind_id, base.kind
),

keywords_agg AS (
    SELECT
        base.kind_id,
        base.kind,
        COUNT(DISTINCT movie_keyword.keyword_id) AS distinct_keyword_count
    FROM base_titles AS base
    JOIN movie_keyword
        ON movie_keyword.movie_id = base.title_id
    GROUP BY base.kind_id, base.kind
),

info_agg AS (
    SELECT
        base.kind_id,
        base.kind,
        COUNT(DISTINCT movie_info_idx.info_type_id) AS distinct_info_type_count
    FROM base_titles AS base
    JOIN movie_info_idx
        ON movie_info_idx.movie_id = base.title_id
    GROUP BY base.kind_id, base.kind
)
SELECT
    t.kind,
    t.title_count,
    t.avg_production_year,
    COALESCE(c.distinct_company_count, 0) AS distinct_company_count,
    COALESCE(k.distinct_keyword_count, 0) AS distinct_keyword_count,
    COALESCE(i.distinct_info_type_count, 0) AS distinct_info_type_count
FROM titles_agg AS t
LEFT JOIN companies_agg AS c
    ON t.kind_id = c.kind_id
LEFT JOIN keywords_agg AS k
    ON t.kind_id = k.kind_id
LEFT JOIN info_agg AS i
    ON t.kind_id = i.kind_id
ORDER BY t.title_count DESC
