WITH alumni_posts AS (
    SELECT
        o.id AS university_id,
        o.name,
        p.id AS post_id,
        p.length
    FROM post p
    JOIN person per
        ON p.creator_person_id = per.id
    JOIN person_study_at_university psu
        ON per.id = psu.person_id
    JOIN organisation o
        ON psu.university_id = o.id
    WHERE o.type = 'University'
),
alumni_likes AS (
    SELECT
        o.id AS university_id,
        COUNT(*) AS total_comment_likes
    FROM person_likes_comment plc
    JOIN person per
        ON plc.person_id = per.id
    JOIN person_study_at_university psu
        ON per.id = psu.person_id
    JOIN organisation o
        ON psu.university_id = o.id
    WHERE o.type = 'University'
    GROUP BY o.id
)
SELECT
    ap.university_id,
    ap.name,
    COUNT(DISTINCT ap.post_id) AS total_posts,
    AVG(ap.length) AS avg_post_length,
    COALESCE(al.total_comment_likes, 0) AS total_comment_likes_by_alumni
FROM alumni_posts ap
LEFT JOIN alumni_likes al
    ON ap.university_id = al.university_id
GROUP BY ap.university_id, ap.name, al.total_comment_likes
ORDER BY total_posts DESC
LIMIT 5
