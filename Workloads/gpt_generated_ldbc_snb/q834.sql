WITH
    all_friends AS (
        SELECT person1_id AS person_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id FROM person_knows_person
    ),
    friend_counts AS (
        SELECT person_id, COUNT(*) AS friend_count
        FROM all_friends
        GROUP BY person_id
    ),
    interest_flags AS (
        SELECT DISTINCT person_id
        FROM person_has_interest_tag
    ),
    local_work AS (
        SELECT p.id AS person_id,
               pw.work_from AS work_from
        FROM person p
        JOIN person_work_at_company pw ON p.id = pw.person_id
        JOIN organisation org ON pw.company_id = org.id
        WHERE org.location_place_id = p.location_city_id
    )
SELECT
    pl.name AS city_name,
    COUNT(p.id) AS person_count,
    COALESCE(AVG(fc.friend_count), 0) AS avg_friends_per_person,
    COUNT(DISTINCT ifp.person_id) AS persons_with_interest,
    AVG(lw.work_from) AS avg_local_work_start_year
FROM person p
JOIN place pl ON p.location_city_id = pl.id
LEFT JOIN friend_counts fc ON p.id = fc.person_id
LEFT JOIN interest_flags ifp ON p.id = ifp.person_id
LEFT JOIN local_work lw ON p.id = lw.person_id
GROUP BY pl.name
ORDER BY person_count DESC
LIMIT 10
