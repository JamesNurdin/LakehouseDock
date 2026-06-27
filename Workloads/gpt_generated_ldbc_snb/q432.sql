/*
  Analytical query: top 10 forums by member count.
  For each forum we show its id, title, creation date, the moderator's full name,
  the total number of members, the number of distinct genders among members,
  and the earliest / latest join dates of members.
*/
WITH member_stats AS (
    SELECT
        fhmp.forum_id,
        COUNT(*) AS member_count,
        COUNT(DISTINCT p.gender) AS gender_count,
        MIN(fhmp.creation_date) AS earliest_member_join,
        MAX(fhmp.creation_date) AS latest_member_join
    FROM forum_has_member_person fhmp
    JOIN person p
        ON fhmp.person_id = p.id
    GROUP BY fhmp.forum_id
)
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date AS forum_creation_date,
    CONCAT(pm.first_name, ' ', pm.last_name) AS moderator_name,
    ms.member_count,
    ms.gender_count,
    ms.earliest_member_join,
    ms.latest_member_join
FROM forum f
LEFT JOIN member_stats ms
    ON f.id = ms.forum_id
LEFT JOIN person pm
    ON f.moderator_person_id = pm.id
ORDER BY ms.member_count DESC NULLS LAST
LIMIT 10
