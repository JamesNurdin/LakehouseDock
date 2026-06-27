WITH movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2010
),
cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT n.id) AS cast_count,
        COUNT(DISTINCT cn.id) AS character_count
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE ci.movie_id IN (SELECT movie_id FROM movies)
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        COUNT(DISTINCT ct.kind) AS company_type_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE mc.movie_id IN (SELECT movie_id FROM movies)
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE mk.movie_id IN (SELECT movie_id FROM movies)
    GROUP BY mk.movie_id
)
SELECT
    m.title,
    m.production_year,
    m.kind,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(cc.character_count, 0) AS character_count,
    COALESCE(compc.company_count, 0) AS company_count,
    COALESCE(compc.company_type_count, 0) AS company_type_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM movies m
LEFT JOIN cast_counts cc ON m.movie_id = cc.movie_id
LEFT JOIN company_counts compc ON m.movie_id = compc.movie_id
LEFT JOIN keyword_counts kc ON m.movie_id = kc.movie_id
ORDER BY cast_count DESC
LIMIT 10
