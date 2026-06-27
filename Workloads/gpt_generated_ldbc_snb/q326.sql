WITH comment_reply_counts AS (
    SELECT
        parent.id AS parent_comment_id,
        COUNT(child.id) AS reply_cnt
    FROM comment parent
    LEFT JOIN comment child
        ON child.parent_comment_id = parent.id
    GROUP BY parent.id
),
student_comments AS (
    SELECT
        psu.university_id,
        psu.class_year,
        p.id AS person_id,
        c.id AS comment_id,
        c.length AS comment_length
    FROM person_study_at_university psu
    JOIN person p ON psu.person_id = p.id
    JOIN comment c ON c.creator_person_id = p.id
)
SELECT
    sc.university_id,
    sc.class_year,
    COUNT(DISTINCT sc.person_id) AS student_count,
    COUNT(DISTINCT sc.comment_id) AS comment_count,
    AVG(sc.comment_length) AS avg_comment_length,
    SUM(COALESCE(lc.like_cnt, 0)) AS total_likes,
    CASE WHEN COUNT(DISTINCT sc.comment_id) = 0 THEN 0
         ELSE SUM(COALESCE(lc.like_cnt, 0)) / COUNT(DISTINCT sc.comment_id) END AS avg_likes_per_comment,
    AVG(crc.reply_cnt) AS avg_replies_per_comment
FROM student_comments sc
LEFT JOIN (
    SELECT
        plc.comment_id,
        COUNT(*) AS like_cnt
    FROM person_likes_comment plc
    GROUP BY plc.comment_id
) lc
    ON sc.comment_id = lc.comment_id
LEFT JOIN comment_reply_counts crc
    ON sc.comment_id = crc.parent_comment_id
GROUP BY sc.university_id, sc.class_year
ORDER BY sc.university_id, sc.class_year
