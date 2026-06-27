WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        MAX(mi.info) AS runtime,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT cn.name) AS character_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN cnm.name END) AS production_company_count,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN name n ON ci.person_id = n.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name cnm ON mc.company_id = cnm.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id AND it.info = 'runtime'
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE t.production_year BETWEEN 2000 AND 2020
      AND kt.kind = 'movie'
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    runtime,
    cast_count,
    character_count,
    production_company_count,
    keyword_count
FROM movie_stats
ORDER BY cast_count DESC
LIMIT 10
