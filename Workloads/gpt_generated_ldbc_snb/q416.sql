WITH comment_likes AS (
    SELECT
        plc.person_id AS liker_person_id,
        plc.comment_id,
        c.creator_person_id AS author_person_id,
        c.length
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
),
author_tags AS (
    SELECT
        p.id AS author_person_id,
        pit.tag_id
    FROM person p
    JOIN person_has_interest_tag pit ON pit.person_id = p.id
),
liker_universities AS (
    SELECT
        p.id AS liker_person_id,
        o.name AS university_name
    FROM person p
    JOIN person_study_at_university psu ON psu.person_id = p.id
    JOIN organisation o ON psu.university_id = o.id
)
SELECT
    lu.university_name,
    at.tag_id,
    COUNT(*) AS total_likes,
    AVG(cl.length) AS avg_comment_length,
    COUNT(DISTINCT cl.comment_id) AS distinct_comments_liked
FROM comment_likes cl
JOIN author_tags at
    ON cl.author_person_id = at.author_person_id
JOIN liker_universities lu
    ON cl.liker_person_id = lu.liker_person_id
WHERE cl.length > 0
GROUP BY lu.university_name, at.tag_id
ORDER BY total_likes DESC
LIMIT 50
