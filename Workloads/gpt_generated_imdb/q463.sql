WITH cast_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
title_cast AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        t.kind_id,
        cc.cast_count
    FROM title t
    JOIN cast_counts cc
        ON t.id = cc.movie_id
    WHERE t.production_year BETWEEN 2000 AND 2020
),
company_movie AS (
    SELECT
        mc.company_id,
        mc.company_type_id,
        tc.movie_id,
        tc.production_year,
        tc.kind_id,
        tc.cast_count
    FROM movie_companies mc
    JOIN title_cast tc
        ON mc.movie_id = tc.movie_id
)
SELECT
    cn.name AS company_name,
    ct.kind AS company_type,
    kt.kind AS title_kind,
    COUNT(DISTINCT cm.movie_id) AS num_movies,
    AVG(cm.cast_count) AS avg_cast_per_movie
FROM company_movie cm
JOIN company_name cn
    ON cm.company_id = cn.id
JOIN company_type ct
    ON cm.company_type_id = ct.id
JOIN kind_type kt
    ON cm.kind_id = kt.id
GROUP BY
    cn.name,
    ct.kind,
    kt.kind
ORDER BY
    num_movies DESC
LIMIT 20
