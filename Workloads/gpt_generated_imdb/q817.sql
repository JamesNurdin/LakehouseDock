WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_company_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT ct.kind) AS distinct_company_type_count,
        COUNT(DISTINCT cn.country_code) AS distinct_company_country_count
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY t.id
),
movie_info_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM title t
    LEFT JOIN movie_info_idx mi ON mi.movie_id = t.id
    GROUP BY t.id
)
SELECT
    mc.movie_id,
    mc.title,
    mc.production_year,
    mc.kind,
    mc.cast_count,
    co.company_count,
    co.distinct_company_type_count,
    co.distinct_company_country_count,
    inf.info_type_count
FROM movie_cast_counts mc
JOIN movie_company_counts co ON co.movie_id = mc.movie_id
JOIN movie_info_counts inf ON inf.movie_id = mc.movie_id
WHERE mc.production_year >= 2000
ORDER BY mc.cast_count DESC
LIMIT 10
