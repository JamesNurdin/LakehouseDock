SELECT
    person_id,
    primary_name,
    gender,
    movie_count,
    aka_name_count,
    info_count,
    total_contributions,
    RANK() OVER (ORDER BY total_contributions DESC) AS contribution_rank
FROM (
    SELECT
        n.id AS person_id,
        n.name AS primary_name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT an.id) AS aka_name_count,
        COUNT(DISTINCT pi.id) AS info_count,
        (COUNT(DISTINCT ci.movie_id) + COUNT(DISTINCT an.id) + COUNT(DISTINCT pi.id)) AS total_contributions
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    GROUP BY n.id, n.name, n.gender
) sub
WHERE total_contributions > 0
ORDER BY total_contributions DESC, primary_name
LIMIT 100
