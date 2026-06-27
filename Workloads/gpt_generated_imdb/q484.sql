WITH movies_per_person AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY n.id, n.name
),
characters_per_person AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT cn.id) AS character_count
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE t.production_year >= 2000
    GROUP BY n.id
),
keywords_per_person AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY n.id
),
aliases_per_person AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT aka.id) AS alias_count
    FROM name n
    LEFT JOIN aka_name aka ON aka.person_id = n.id
    GROUP BY n.id
)
SELECT *
FROM (
    SELECT
        mp.person_name,
        mp.movie_count,
        cp.character_count,
        kp.keyword_count,
        ap.alias_count,
        ROW_NUMBER() OVER (ORDER BY mp.movie_count DESC) AS rank
    FROM movies_per_person mp
    LEFT JOIN characters_per_person cp ON cp.person_id = mp.person_id
    LEFT JOIN keywords_per_person kp ON kp.person_id = mp.person_id
    LEFT JOIN aliases_per_person ap ON ap.person_id = mp.person_id
) ranked
WHERE ranked.rank <= 10
ORDER BY ranked.rank
