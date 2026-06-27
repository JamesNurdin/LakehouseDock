WITH keyword_stats AS (
    SELECT
        kt.kind AS kind,
        kw.keyword AS keyword,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_members
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY kt.kind, kw.keyword
),
ranked_keywords AS (
    SELECT
        kind,
        keyword,
        movie_count,
        avg_production_year,
        distinct_cast_members,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY movie_count DESC) AS rn
    FROM keyword_stats
)
SELECT
    kind,
    keyword,
    movie_count,
    avg_production_year,
    distinct_cast_members
FROM ranked_keywords
WHERE rn <= 5
ORDER BY kind, rn
