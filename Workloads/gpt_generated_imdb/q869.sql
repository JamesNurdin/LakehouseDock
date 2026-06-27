WITH company_kind_stats AS (
    SELECT
        title.kind_id,
        movie_companies.company_id,
        COUNT(DISTINCT title.id) AS movie_cnt,
        AVG(title.production_year) AS avg_year
    FROM title
    JOIN movie_companies
        ON movie_companies.movie_id = title.id
    WHERE title.production_year >= 2000
    GROUP BY title.kind_id, movie_companies.company_id
),
company_kind_info AS (
    SELECT
        title.kind_id,
        movie_companies.company_id,
        movie_info.info_type_id,
        COUNT(*) AS info_type_cnt
    FROM title
    JOIN movie_companies
        ON movie_companies.movie_id = title.id
    JOIN movie_info
        ON movie_info.movie_id = title.id
    WHERE title.production_year >= 2000
    GROUP BY title.kind_id, movie_companies.company_id, movie_info.info_type_id
),
company_kind_top_info AS (
    SELECT
        kind_id,
        company_id,
        info_type_id,
        info_type_cnt,
        ROW_NUMBER() OVER (PARTITION BY kind_id, company_id ORDER BY info_type_cnt DESC) AS rn
    FROM company_kind_info
)
SELECT
    kind_type.kind,
    cks.company_id,
    cks.movie_cnt,
    cks.avg_year,
    ckt.info_type_id AS top_info_type_id,
    ckt.info_type_cnt AS top_info_type_cnt
FROM company_kind_stats AS cks
JOIN kind_type
    ON cks.kind_id = kind_type.id
JOIN company_kind_top_info AS ckt
    ON ckt.kind_id = cks.kind_id
    AND ckt.company_id = cks.company_id
    AND ckt.rn = 1
ORDER BY kind_type.kind, cks.movie_cnt DESC
LIMIT 50
