WITH forum_members AS (
    SELECT fm.forum_id,
           p.id AS person_id
    FROM forum_has_member_person fm
    JOIN person p ON fm.person_id = p.id
),
member_universities AS (
    SELECT fm.forum_id,
           o.id AS university_id,
           o.name AS university_name,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_members fm
    JOIN person_study_at_university psu ON fm.person_id = psu.person_id
    JOIN organisation o ON psu.university_id = o.id
    GROUP BY fm.forum_id, o.id, o.name
),
forum_comments AS (
    SELECT fm.forum_id,
           c.id AS comment_id,
           c.length AS comment_length
    FROM comment c
    JOIN person p ON c.creator_person_id = p.id
    JOIN forum_has_member_person fm ON fm.person_id = p.id
),
comment_likes AS (
    SELECT fc.forum_id,
           COUNT(pl.person_id) AS like_count
    FROM forum_comments fc
    JOIN person_likes_comment pl ON pl.comment_id = fc.comment_id
    GROUP BY fc.forum_id
),
forum_comment_stats AS (
    SELECT fc.forum_id,
           COUNT(DISTINCT fc.comment_id) AS total_comments,
           AVG(fc.comment_length) AS avg_comment_length
    FROM forum_comments fc
    GROUP BY fc.forum_id
),
top_universities AS (
    SELECT mu.forum_id,
           mu.university_name,
           mu.member_count,
           ROW_NUMBER() OVER (PARTITION BY mu.forum_id ORDER BY mu.member_count DESC) AS rn
    FROM member_universities mu
)
SELECT f.id AS forum_id,
       f.title AS forum_title,
       COALESCE(cs.total_comments, 0) AS total_comments,
       COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(cl.like_count, 0) AS total_comment_likes,
       tu.university_name,
       tu.member_count AS university_member_count
FROM forum f
LEFT JOIN forum_comment_stats cs ON cs.forum_id = f.id
LEFT JOIN comment_likes cl ON cl.forum_id = f.id
LEFT JOIN top_universities tu ON tu.forum_id = f.id AND tu.rn = 1
ORDER BY total_comments DESC
LIMIT 10
