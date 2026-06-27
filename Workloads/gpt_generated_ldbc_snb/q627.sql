/*
  Forum‑level engagement summary
  – Number of members (total, male, female)
  – Comments created by members (count, average length, total likes)
  – Diversity of interests (distinct tags) among members
  The query follows the allowed join rules and uses only the listed tables.
*/
WITH comment_likes AS (
    SELECT
        c.id AS comment_id,
        c.creator_person_id AS creator_id,
        c.length AS comment_length,
        COUNT(plc.person_id) AS like_count
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.id, c.creator_person_id, c.length
),
forum_members AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id) AS member_count,
        SUM(CASE WHEN p.gender = 'male'   THEN 1 ELSE 0 END) AS male_members,
        SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) AS female_members
    FROM forum f
    JOIN forum_has_member_person fhm
        ON fhm.forum_id = f.id
    JOIN person p
        ON fhm.person_id = p.id
    GROUP BY f.id, f.title
),
member_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT cl.comment_id) AS comment_count,
        AVG(cl.comment_length)        AS avg_comment_length,
        SUM(cl.like_count)            AS total_comment_likes
    FROM forum f
    JOIN forum_has_member_person fhm
        ON fhm.forum_id = f.id
    JOIN person p
        ON fhm.person_id = p.id
    JOIN comment_likes cl
        ON cl.creator_id = p.id
    GROUP BY f.id
),
member_tags AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT pit.tag_id) AS distinct_tag_count
    FROM forum f
    JOIN forum_has_member_person fhm
        ON fhm.forum_id = f.id
    JOIN person p
        ON fhm.person_id = p.id
    JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
    GROUP BY f.id
)
SELECT
    fm.forum_id,
    fm.forum_title,
    fm.member_count,
    fm.male_members,
    fm.female_members,
    mc.comment_count,
    mc.avg_comment_length,
    mc.total_comment_likes,
    mt.distinct_tag_count
FROM forum_members fm
LEFT JOIN member_comments mc
    ON mc.forum_id = fm.forum_id
LEFT JOIN member_tags mt
    ON mt.forum_id = fm.forum_id
ORDER BY fm.member_count DESC
LIMIT 20
