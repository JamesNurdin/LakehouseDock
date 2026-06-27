WITH movies_per_person AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        COUNT(DISTINCT t.id) AS movie_cnt
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    GROUP BY n.id, n.name, n.gender
),
characters_per_person AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT cn.id) AS char_cnt
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY n.id
),
aka_per_person AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT a.id) AS aka_cnt
    FROM name n
    JOIN aka_name a ON a.person_id = n.id
    GROUP BY n.id
)
SELECT
    mp.person_name,
    mp.gender,
    mp.movie_cnt,
    COALESCE(cp.char_cnt, 0) AS char_cnt,
    COALESCE(ap.aka_cnt, 0) AS aka_cnt
FROM movies_per_person mp
LEFT JOIN characters_per_person cp ON cp.person_id = mp.person_id
LEFT JOIN aka_per_person ap ON ap.person_id = mp.person_id
ORDER BY mp.movie_cnt DESC
LIMIT 10
