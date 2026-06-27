WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        kt.kind AS kind,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT cn.id) AS character_count,
        COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'production') AS production_company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        AVG(CAST(mi.info AS double)) FILTER (WHERE it.info = 'rating') AS avg_rating
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    WHERE t.production_year >= 2000
    GROUP BY
        t.id,
        t.title,
        kt.kind,
        t.production_year
)
SELECT
    movie_id,
    title,
    kind,
    production_year,
    cast_count,
    character_count,
    production_company_count,
    keyword_count,
    avg_rating
FROM movie_stats
ORDER BY cast_count DESC
LIMIT 100
