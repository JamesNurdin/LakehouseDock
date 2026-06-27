WITH movie_agg AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT ct.kind) AS company_type_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN company_type ct
        ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    WHERE kt.kind = 'movie'
    GROUP BY
        t.id,
        t.title,
        t.production_year,
        kt.kind
),
top_cast AS (
    SELECT
        ci.movie_id,
        n.name AS cast_name,
        cn.name AS character_name,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rn
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    LEFT JOIN char_name cn
        ON ci.person_role_id = cn.id
    WHERE ci.nr_order IS NOT NULL
)
SELECT
    ma.title,
    ma.production_year,
    ma.kind,
    ma.cast_count,
    ma.company_count,
    ma.company_type_count,
    ma.keyword_count,
    tc.cast_name,
    tc.character_name,
    tc.nr_order
FROM movie_agg ma
JOIN top_cast tc
    ON ma.movie_id = tc.movie_id
WHERE tc.rn <= 3
ORDER BY ma.cast_count DESC, ma.title
LIMIT 100
