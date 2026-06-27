/* Top 5 countries by distinct‑movie count for each company type */
WITH type_country_stats AS (
    SELECT
        ct.kind                AS kind,
        cn.country_code        AS country_code,
        COUNT(DISTINCT cn.id)  AS distinct_company_cnt,
        COUNT(DISTINCT mc.movie_id) AS distinct_movie_cnt
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    GROUP BY ct.kind, cn.country_code
),
ranked_countries AS (
    SELECT
        kind,
        country_code,
        distinct_company_cnt,
        distinct_movie_cnt,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY distinct_movie_cnt DESC) AS country_rank
    FROM type_country_stats
)
SELECT
    kind,
    country_code,
    distinct_company_cnt,
    distinct_movie_cnt,
    country_rank
FROM ranked_countries
WHERE country_rank <= 5
ORDER BY kind, country_rank
