WITH forum_member_details AS (
    SELECT
        fhm.forum_id,
        p.gender,
        p.birthday,
        p.email,
        fhm.creation_date AS membership_creation_date
    FROM forum_has_member_person fhm
    JOIN person p
        ON fhm.person_id = p.id
)
SELECT
    forum_id,
    COUNT(*) AS total_members,
    COUNT(DISTINCT gender) AS distinct_genders,
    AVG(DATE_DIFF('year', CAST(date_parse(birthday, '%Y-%m-%d') AS date), CURRENT_DATE)) AS avg_age_years,
    AVG(LENGTH(email)) AS avg_email_length,
    MIN(CAST(date_parse(membership_creation_date, '%Y-%m-%d') AS date)) AS earliest_membership_date
FROM forum_member_details
GROUP BY forum_id
ORDER BY total_members DESC
LIMIT 5
