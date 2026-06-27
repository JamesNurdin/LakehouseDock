WITH badge_counts AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
post_counts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           COALESCE(SUM(score), 0) AS post_score_sum,
           COALESCE(SUM(viewcount), 0) AS post_view_sum
    FROM posts
    GROUP BY owneruserid
),
comment_counts AS (
    SELECT userid,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
comment_received_counts AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS comment_received_count
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
votes_cast_counts AS (
    SELECT userid,
           COUNT(*) AS votes_cast_count
    FROM votes
    GROUP BY userid
),
votes_received_counts AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS votes_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
edit_counts AS (
    SELECT lasteditoruserid AS userid,
           COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
tag_counts AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
posthistory_counts AS (
    SELECT userid,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.post_score_sum, 0) AS post_score_sum,
    COALESCE(p.post_view_sum, 0) AS post_view_sum,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(cr.comment_received_count, 0) AS comment_received_count,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    (COALESCE(p.post_count, 0) * 5
     + COALESCE(c.comment_count, 0) * 2
     + COALESCE(vc.votes_cast_count, 0) * 1
     + COALESCE(vr.votes_received_count, 0) * 3
     + COALESCE(b.badge_count, 0) * 4
     + COALESCE(e.edit_count, 0) * 2
     + COALESCE(t.tag_count, 0) * 1) AS activity_score
FROM users u
LEFT JOIN badge_counts b ON u.id = b.userid
LEFT JOIN post_counts p ON u.id = p.userid
LEFT JOIN comment_counts c ON u.id = c.userid
LEFT JOIN comment_received_counts cr ON u.id = cr.userid
LEFT JOIN votes_cast_counts vc ON u.id = vc.userid
LEFT JOIN votes_received_counts vr ON u.id = vr.userid
LEFT JOIN edit_counts e ON u.id = e.userid
LEFT JOIN tag_counts t ON u.id = t.userid
LEFT JOIN posthistory_counts ph ON u.id = ph.userid
ORDER BY activity_score DESC
LIMIT 10
