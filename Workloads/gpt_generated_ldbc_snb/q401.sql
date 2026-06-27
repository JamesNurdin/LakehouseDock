WITH forum_member_comments AS (
    SELECT
        fhm.forum_id,
        p.id AS person_id,
        c.id AS comment_id,
        c.length AS comment_length,
        c.creation_date AS comment_creation_date,
        c.parent_post_id,
        c.parent_comment_id,
        c.location_country_id,
        c.location_ip,
        c.browser_used,
        c.content
    FROM forum_has_member_person fhm
    JOIN person p
        ON p.id = fhm.person_id
    JOIN comment c
        ON c.creator_person_id = p.id
    WHERE c.length > 0
),
member_tags AS (
    SELECT
        p.id AS person_id,
        t.id AS tag_id,
        t.name AS tag_name
    FROM person p
    JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
    JOIN tag t
        ON t.id = pit.tag_id
)
SELECT
    fmc.forum_id,
    mt.tag_name,
    COUNT(DISTINCT fmc.person_id) AS num_members,
    COUNT(fmc.comment_id) AS total_comments,
    AVG(fmc.comment_length) AS avg_comment_length
FROM forum_member_comments fmc
JOIN member_tags mt
    ON mt.person_id = fmc.person_id
GROUP BY fmc.forum_id, mt.tag_name
ORDER BY total_comments DESC
LIMIT 50
