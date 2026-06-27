WITH keyword_stats AS (
    SELECT
        kt.kind,
        kw.keyword,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(DISTINCT t.production_year) AS avg_year,
        COUNT(DISTINCT mc.company_type_id) AS distinct_company_type_count
    FROM title t
    JOIN kind_type kt ON kt.id = t.kind_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword kw ON kw.id = mk.keyword_id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY kt.kind, kw.keyword
),
ranked_stats AS (
    SELECT
        kind,
        keyword,
        movie_count,
        avg_year,
        distinct_company_type_count,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY movie_count DESC) AS rank_in_kind
    FROM keyword_stats
)
SELECT
    kind,
    keyword,
    movie_count,
    avg_year,
    distinct_company_type_count,
    rank_in_kind
FROM ranked_stats
WHERE rank_in_kind <= 5
ORDER BY kind, rank_in_kind
