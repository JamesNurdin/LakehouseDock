WITH actor_movies AS (
    SELECT
        ci.person_id,
        n.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(ci.nr_order) AS avg_nr_order
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    WHERE n.gender IS NOT NULL
    GROUP BY ci.person_id, n.name
),
actor_movie_info AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT mi.info_type_id) AS distinct_movie_info_type_cnt,
        COUNT(DISTINCT mi.info) AS distinct_movie_info_cnt
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN movie_info mi ON mi.movie_id = t.id
    GROUP BY ci.person_id
),
person_info_agg AS (
    SELECT
        pi.person_id,
        COUNT(DISTINCT pi.info_type_id) AS distinct_person_info_type_cnt,
        COUNT(*) AS total_person_info_cnt
    FROM person_info pi
    GROUP BY pi.person_id
)
SELECT
    am.name,
    am.movie_count,
    am.avg_nr_order,
    ami.distinct_movie_info_type_cnt,
    ami.distinct_movie_info_cnt,
    pia.distinct_person_info_type_cnt,
    pia.total_person_info_cnt
FROM actor_movies am
LEFT JOIN actor_movie_info ami ON am.person_id = ami.person_id
LEFT JOIN person_info_agg pia ON am.person_id = pia.person_id
ORDER BY am.movie_count DESC
LIMIT 10
