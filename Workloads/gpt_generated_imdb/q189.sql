-- Analytical query: production year & kind overview with rating, keyword richness, and dominant company type
WITH rating AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
keyword_agg AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT kw.keyword) AS keyword_cnt
    FROM movie_keyword mk
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mk.movie_id
),
movie_metrics AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(r.rating) AS avg_rating,
        SUM(COALESCE(ka.keyword_cnt, 0)) AS total_distinct_keywords
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN rating r ON r.movie_id = t.id
    LEFT JOIN keyword_agg ka ON ka.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind
),
company_type_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        ct.kind AS company_type_kind,
        COUNT(*) AS ct_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind, ct.kind
),
most_common_company_type AS (
    SELECT
        production_year,
        kind,
        company_type_kind,
        ct_cnt,
        ROW_NUMBER() OVER (PARTITION BY production_year, kind ORDER BY ct_cnt DESC) AS rn
    FROM company_type_counts
)
SELECT
    mm.production_year,
    mm.kind,
    mm.movie_count,
    mm.avg_rating,
    mm.total_distinct_keywords,
    mcc.company_type_kind AS most_common_company_type
FROM movie_metrics mm
LEFT JOIN most_common_company_type mcc
    ON mm.production_year = mcc.production_year
   AND mm.kind = mcc.kind
   AND mcc.rn = 1
ORDER BY mm.movie_count DESC
LIMIT 20
