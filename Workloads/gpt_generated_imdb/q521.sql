WITH kind_stats AS (
    SELECT
        kt.kind,
        COUNT(DISTINCT t.id) AS title_count,
        AVG(t.production_year) AS avg_production_year,
        COUNT(DISTINCT kw.id) AS distinct_keyword_count,
        COUNT(DISTINCT mc.company_id) AS distinct_company_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY kt.kind
),
keyword_counts AS (
    SELECT
        kt.kind,
        kw.keyword,
        COUNT(DISTINCT t.id) AS title_keyword_count,
        ROW_NUMBER() OVER (PARTITION BY kt.kind ORDER BY COUNT(DISTINCT t.id) DESC) AS keyword_rank
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE t.production_year IS NOT NULL
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY kt.kind, kw.keyword
)
SELECT
    ks.kind,
    ks.title_count,
    ks.avg_production_year,
    ks.distinct_keyword_count,
    ks.distinct_company_count,
    kc.keyword,
    kc.title_keyword_count,
    kc.keyword_rank
FROM kind_stats ks
JOIN keyword_counts kc ON kc.kind = ks.kind
WHERE kc.keyword_rank <= 3
ORDER BY ks.kind, kc.keyword_rank
