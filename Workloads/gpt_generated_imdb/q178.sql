WITH company_stats AS (
    SELECT
        cn.name AS company_name,
        kt.kind AS title_kind,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        COUNT(DISTINCT k.id) AS distinct_keyword_count
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk
        ON t.id = mk.movie_id
    LEFT JOIN keyword k
        ON mk.keyword_id = k.id
    WHERE ct.kind = 'production'
      AND t.production_year IS NOT NULL
    GROUP BY cn.name, kt.kind
)
SELECT
    company_name,
    title_kind,
    movie_count,
    avg_production_year,
    distinct_keyword_count,
    RANK() OVER (PARTITION BY title_kind ORDER BY movie_count DESC) AS company_rank
FROM company_stats
ORDER BY title_kind, company_rank
LIMIT 50
