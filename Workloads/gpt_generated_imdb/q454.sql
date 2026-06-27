WITH company_movie_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        ctype.kind AS company_type,
        ct.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ct.id) AS movie_count,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_members
    FROM movie_companies mc
    JOIN title ct
        ON mc.movie_id = ct.id
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ctype
        ON mc.company_type_id = ctype.id
    JOIN kind_type kt
        ON ct.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = ct.id
    WHERE ct.production_year IS NOT NULL
    GROUP BY cn.id, cn.name, ctype.kind, ct.production_year, kt.kind
)
SELECT
    company_name,
    company_type,
    production_year,
    kind,
    movie_count,
    distinct_cast_members,
    distinct_cast_members * 1.0 / movie_count AS avg_cast_per_movie
FROM company_movie_stats
WHERE movie_count >= 5
ORDER BY movie_count DESC, distinct_cast_members DESC
LIMIT 50
