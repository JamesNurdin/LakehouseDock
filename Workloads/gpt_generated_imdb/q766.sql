WITH movie_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(c.nr_order) AS avg_nr_order,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM name n
    JOIN cast_info c ON c.person_id = n.id
    JOIN title t ON t.id = c.movie_id
    WHERE t.production_year >= 2000
    GROUP BY n.id, n.name, n.gender
),
aka_stats AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT a.id) AS aka_name_count
    FROM name n
    LEFT JOIN aka_name a ON a.person_id = n.id
    GROUP BY n.id
),
info_stats AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT pi.id) AS info_count
    FROM name n
    LEFT JOIN person_info pi ON pi.person_id = n.id
    GROUP BY n.id
)
SELECT
    ms.person_id,
    ms.person_name,
    ms.gender,
    ms.movie_count,
    ak.aka_name_count,
    i.info_count,
    ms.avg_nr_order,
    ms.first_year,
    ms.last_year,
    RANK() OVER (ORDER BY ms.movie_count DESC) AS movie_rank
FROM movie_stats ms
LEFT JOIN aka_stats ak ON ak.person_id = ms.person_id
LEFT JOIN info_stats i ON i.person_id = ms.person_id
ORDER BY ms.movie_count DESC, ms.person_name
LIMIT 20
