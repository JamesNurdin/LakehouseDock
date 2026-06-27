WITH
    user_posts AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS post_count,
               COALESCE(SUM(p.score), 0) AS post_score_sum
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT p.lasteditoruserid AS userid,
               COUNT(*) AS edit_count
        FROM posts p
        WHERE p.lasteditoruserid IS NOT NULL
        GROUP BY p.lasteditoruserid
    ),
    user_comments AS (
        SELECT c.userid,
               COUNT(*) AS comment_count,
               COALESCE(SUM(c.score), 0) AS comment_score_sum
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes_cast AS (
        SELECT v.userid,
               COUNT(*) AS votes_cast,
               COALESCE(SUM(v.bountyamount), 0) AS bounty_total
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS votes_received,
               COALESCE(SUM(v.bountyamount), 0) AS bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.post_score_sum, 0) AS post_score_sum,
       COALESCE(ue.edit_count, 0) AS edit_count,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uvc.bounty_total, 0) AS bounty_total,
       COALESCE(uvr.bounty_received, 0) AS bounty_received
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_edits ue ON u.id = ue.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast uvc ON u.id = uvc.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.userid
WHERE u.reputation > 0
ORDER BY post_score_sum DESC
LIMIT 100
