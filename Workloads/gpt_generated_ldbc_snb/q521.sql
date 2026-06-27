WITH tag_counts AS (
    SELECT person_id,
           COUNT(DISTINCT tag_id) AS tag_count
    FROM person_has_interest_tag
    GROUP BY person_id
),
comment_stats AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    JOIN person p ON fm.person_id = p.id
    JOIN comment c ON c.creator_person_id = p.id
    GROUP BY f.id, f.title
),
like_stats AS (
    SELECT f.id AS forum_id,
           COUNT(plc.person_id) AS total_comment_likes,
           COUNT(DISTINCT plc.person_id) AS distinct_likers
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    JOIN person p ON fm.person_id = p.id
    JOIN comment c ON c.creator_person_id = p.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY f.id
),
member_stats AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS member_count,
           AVG(tc.tag_count) AS avg_tags_per_member
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    JOIN person p ON fm.person_id = p.id
    LEFT JOIN tag_counts tc ON tc.person_id = p.id
    GROUP BY f.id
)
SELECT cs.forum_id,
       cs.forum_title,
       cs.comment_count,
       cs.avg_comment_length,
       ls.total_comment_likes,
       ls.distinct_likers,
       ms.member_count,
       ms.avg_tags_per_member
FROM comment_stats cs
JOIN like_stats ls ON ls.forum_id = cs.forum_id
JOIN member_stats ms ON ms.forum_id = cs.forum_id
ORDER BY ls.total_comment_likes DESC
LIMIT 10
