WITH actor_details AS (
    SELECT
        n.id AS person_id,
        n.name,
        n.gender,
        ci.movie_id,
        t.production_year,
        cn.id AS company_id,
        ch.id AS character_id
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN char_name ch ON ci.person_role_id = ch.id
    WHERE kt.kind = 'movie'
),
aka_agg AS (
    SELECT person_id, array_agg(DISTINCT name) AS aka_names
    FROM aka_name
    GROUP BY person_id
)
SELECT
    ad.person_id,
    ad.name,
    ad.gender,
    aka.aka_names,
    COUNT(DISTINCT ad.movie_id) AS movie_count,
    COUNT(DISTINCT ad.character_id) AS distinct_character_count,
    COUNT(DISTINCT ad.company_id) AS distinct_company_count,
    MIN(ad.production_year) AS earliest_production_year
FROM actor_details ad
LEFT JOIN aka_agg aka ON ad.person_id = aka.person_id
GROUP BY ad.person_id, ad.name, ad.gender, aka.aka_names
HAVING COUNT(DISTINCT ad.movie_id) >= 5
ORDER BY movie_count DESC, earliest_production_year ASC
LIMIT 20
