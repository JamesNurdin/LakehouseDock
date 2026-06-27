WITH movie_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(DISTINCT t.id) AS movie_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
    GROUP BY t.production_year, kt.kind
),
per_movie_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
avg_company_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        AVG(pmc.company_cnt) AS avg_company_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN per_movie_company_counts pmc ON pmc.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.production_year, kt.kind
),
per_movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
total_keyword_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        SUM(pmk.keyword_cnt) AS total_keywords
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN per_movie_keyword_counts pmk ON pmk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.production_year, kt.kind
),
distinct_company_countries AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(DISTINCT cn.country_code) AS distinct_company_countries
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production'
      AND t.production_year >= 2000
    GROUP BY t.production_year, kt.kind
)
SELECT
    mc.production_year,
    mc.kind,
    mc.movie_count,
    ac.avg_company_cnt,
    tk.total_keywords,
    dc.distinct_company_countries
FROM movie_counts mc
LEFT JOIN avg_company_counts ac
    ON ac.production_year = mc.production_year
   AND ac.kind = mc.kind
LEFT JOIN total_keyword_counts tk
    ON tk.production_year = mc.production_year
   AND tk.kind = mc.kind
LEFT JOIN distinct_company_countries dc
    ON dc.production_year = mc.production_year
   AND dc.kind = mc.kind
ORDER BY mc.production_year DESC, mc.kind
