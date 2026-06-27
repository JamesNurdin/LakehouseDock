WITH per_person_info AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        it.id AS info_type_id,
        it.info AS info_type,
        COUNT(DISTINCT mi.movie_id) AS movie_count,
        AVG(mi.note) AS avg_movie_note
    FROM person_info pi
    JOIN name n
        ON pi.person_id = n.id
    JOIN info_type it
        ON pi.info_type_id = it.id
    LEFT JOIN movie_info_idx mi
        ON mi.info_type_id = it.id
    GROUP BY n.id, n.name, it.id, it.info
),
person_totals AS (
    SELECT
        person_id,
        person_name,
        SUM(movie_count) AS total_movies
    FROM per_person_info
    GROUP BY person_id, person_name
),
ranked_info AS (
    SELECT
        per_person_info.person_id,
        per_person_info.person_name,
        per_person_info.info_type,
        per_person_info.movie_count,
        per_person_info.avg_movie_note,
        ROW_NUMBER() OVER (PARTITION BY per_person_info.person_id ORDER BY per_person_info.movie_count DESC) AS info_rank
    FROM per_person_info
)
SELECT
    person_totals.person_id,
    person_totals.person_name,
    person_totals.total_movies,
    ranked_info.info_type,
    ranked_info.movie_count,
    ranked_info.avg_movie_note,
    ranked_info.info_rank
FROM ranked_info
JOIN person_totals
    ON ranked_info.person_id = person_totals.person_id
WHERE ranked_info.info_rank = 1
ORDER BY person_totals.total_movies DESC
LIMIT 20
