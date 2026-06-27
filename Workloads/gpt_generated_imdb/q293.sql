WITH movies_per_person AS (
    SELECT ci.person_id,
           COUNT(DISTINCT ci.movie_id) AS total_movies
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
    GROUP BY ci.person_id
),
characters_per_person AS (
    SELECT ci.person_id,
           COUNT(DISTINCT ci.person_role_id) AS total_characters
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE ci.person_role_id IS NOT NULL
      AND kt.kind = 'movie'
    GROUP BY ci.person_id
),
aka_per_person AS (
    SELECT person_id,
           COUNT(*) AS total_aka_names
    FROM aka_name
    GROUP BY person_id
),
companies_per_person AS (
    SELECT ci.person_id,
           COUNT(DISTINCT mc.company_id) AS total_companies
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    WHERE kt.kind = 'movie'
    GROUP BY ci.person_id
)
SELECT n.id,
       n.name,
       n.gender,
       COALESCE(m.total_movies, 0)      AS total_movies,
       COALESCE(c.total_characters, 0) AS total_characters,
       COALESCE(a.total_aka_names, 0)  AS total_aka_names,
       COALESCE(comp.total_companies, 0) AS total_companies
FROM name n
LEFT JOIN movies_per_person m    ON n.id = m.person_id
LEFT JOIN characters_per_person c ON n.id = c.person_id
LEFT JOIN aka_per_person a        ON n.id = a.person_id
LEFT JOIN companies_per_person comp ON n.id = comp.person_id
ORDER BY total_movies DESC, n.name
LIMIT 20
