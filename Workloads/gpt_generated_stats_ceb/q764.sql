WITH post_counts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count
    FROM posts
    GROUP BY owneruserid
),
comment_counts AS (
    SELECT userid,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
badge_counts AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
vote_counts AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
tag_counts AS (
    SELECT p.owneruserid AS userid,
           COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id,
       u.reputation,
       COALESCE(pc.post_count, 0)      AS post_count,
       COALESCE(cc.comment_count, 0)   AS comment_count,
       COALESCE(vc.votes_received, 0) AS votes_received,
       COALESCE(bc.badge_count, 0)    AS badge_count,
       COALESCE(tc.tag_count, 0)      AS tag_count,
       (2 * COALESCE(pc.post_count, 0)
        + COALESCE(cc.comment_count, 0)
        + 3 * COALESCE(vc.votes_received, 0)
        + 5 * COALESCE(bc.badge_count, 0)
        + COALESCE(tc.tag_count, 0))   AS activity_score
FROM users u
LEFT JOIN post_counts pc ON u.id = pc.userid
LEFT JOIN comment_counts cc ON u.id = cc.userid
LEFT JOIN badge_counts bc ON u.id = bc.userid
LEFT JOIN vote_counts vc ON u.id = vc.userid
LEFT JOIN tag_counts tc ON u.id = tc.userid
ORDER BY activity_score DESC
LIMIT 10
