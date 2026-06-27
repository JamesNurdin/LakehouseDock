WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT n.id) FILTER (WHERE ak.id IS NOT NULL) AS cast_with_alias_count,
        COUNT(DISTINCT ch.id) AS character_count,
        COUNT(DISTINCT cn.id) AS company_count,
        COUNT(DISTINCT ct.kind) AS company_type_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT cn.country_code) AS country_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN name n ON ci.person_id = n.id
    LEFT JOIN aka_name ak ON ak.person_id = n.id
    LEFT JOIN char_name ch ON ci.person_role_id = ch.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    cast_count,
    cast_with_alias_count,
    character_count,
    company_count,
    company_type_count,
    keyword_count,
    country_count
FROM movie_stats
ORDER BY cast_count DESC
LIMIT 100
