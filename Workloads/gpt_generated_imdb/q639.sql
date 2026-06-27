WITH movie_cast AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_member_cnt
    FROM cast_info ci
    JOIN title t
        ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
),
movie_companies AS (
    SELECT 
        t.id AS movie_id,
        array_agg(DISTINCT cn.name) AS company_names,
        array_agg(DISTINCT ct.kind) AS company_kinds
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    GROUP BY t.id
)
SELECT 
    mc.title,
    mc.production_year,
    mc.cast_member_cnt,
    c.company_names,
    c.company_kinds
FROM movie_cast mc
JOIN movie_companies c
    ON mc.movie_id = c.movie_id
ORDER BY mc.cast_member_cnt DESC
LIMIT 10
