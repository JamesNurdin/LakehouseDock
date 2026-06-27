WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) FILTER (WHERE cn.country_code = 'US') AS us_company_count,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN keyword k
        ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN company_name cn
        ON mc.company_id = cn.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    GROUP BY
        t.id,
        t.title,
        t.production_year,
        kt.kind
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    keyword_count,
    us_company_count,
    cast_count,
    ROW_NUMBER() OVER (PARTITION BY kind ORDER BY cast_count DESC) AS rank_within_kind
FROM movie_stats
WHERE keyword_count >= 3
  AND us_company_count >= 2
ORDER BY kind, rank_within_kind
LIMIT 100
