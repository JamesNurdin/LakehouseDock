WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT n.id) AS cast_count,
        COUNT(DISTINCT cn.id) AS company_count,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM title AS t
    LEFT JOIN kind_type AS kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info AS ci
        ON ci.movie_id = t.id
    LEFT JOIN name AS n
        ON ci.person_id = n.id
    LEFT JOIN movie_companies AS mc
        ON mc.movie_id = t.id
    LEFT JOIN company_name AS cn
        ON mc.company_id = cn.id
    LEFT JOIN movie_keyword AS mk
        ON mk.movie_id = t.id
    LEFT JOIN keyword AS k
        ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    cast_count,
    company_count,
    keyword_count
FROM movie_stats
ORDER BY cast_count DESC
LIMIT 10
