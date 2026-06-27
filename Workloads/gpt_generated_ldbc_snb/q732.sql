WITH forum_members AS (
    SELECT
        fhm.forum_id,
        p.id AS person_id,
        p.gender,
        p.language
    FROM forum_has_member_person fhm
    JOIN person p ON fhm.person_id = p.id
),
member_posts AS (
    SELECT
        fm.forum_id,
        fm.person_id,
        po.id AS post_id,
        po.length AS post_length
    FROM forum_members fm
    JOIN post po ON po.creator_person_id = fm.person_id
),
member_likes AS (
    SELECT DISTINCT
        fm.forum_id,
        fm.person_id
    FROM forum_members fm
    JOIN person_likes_comment plc ON plc.person_id = fm.person_id
),
member_university AS (
    SELECT DISTINCT
        fm.forum_id,
        fm.person_id
    FROM forum_members fm
    JOIN person_study_at_university psu ON psu.person_id = fm.person_id
)
SELECT
    fm.forum_id,
    COUNT(DISTINCT fm.person_id) AS total_members,
    COUNT(DISTINCT mp.post_id) AS total_posts,
    AVG(mp.post_length) AS avg_post_length,
    COUNT(DISTINCT ml.person_id) AS members_who_liked_comments,
    COUNT(DISTINCT mu.person_id) AS members_who_studied_university,
    SUM(CASE WHEN fm.gender = 'male' THEN 1 ELSE 0 END) AS male_members,
    SUM(CASE WHEN fm.gender = 'female' THEN 1 ELSE 0 END) AS female_members
FROM forum_members fm
LEFT JOIN member_posts mp
    ON mp.forum_id = fm.forum_id AND mp.person_id = fm.person_id
LEFT JOIN member_likes ml
    ON ml.forum_id = fm.forum_id AND ml.person_id = fm.person_id
LEFT JOIN member_university mu
    ON mu.forum_id = fm.forum_id AND mu.person_id = fm.person_id
GROUP BY fm.forum_id
ORDER BY total_posts DESC
LIMIT 100
