WITH
    user_posts AS (
        SELECT owneruserid AS userid,
               COUNT(*) AS post_count,
               SUM(score) AS post_score_sum,
               AVG(score) AS post_score_avg
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT userid,
               COUNT(*) AS comment_count,
               SUM(score) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT userid,
               COUNT(*) AS votes_cast,
               COALESCE(SUM(bountyamount), 0) AS bounty_cast_sum
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS votes_received,
               COALESCE(SUM(v.bountyamount), 0) AS bounty_received_sum
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT userid,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_tags AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory AS (
        SELECT userid,
               COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    )
SELECT u.id,
       u.reputation,
       u.creationdate,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.post_score_sum, 0) AS post_score_sum,
       COALESCE(up.post_score_avg, 0) AS post_score_avg,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvc.bounty_cast_sum, 0) AS bounty_cast_sum,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uvr.bounty_received_sum, 0) AS bounty_received_sum,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ut.tag_count, 0) AS tag_count,
       COALESCE(upL.postlink_count, 0) AS postlink_count,
       COALESCE(upH.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts up       ON u.id = up.userid
LEFT JOIN user_comments uc    ON u.id = uc.userid
LEFT JOIN user_votes_cast uvc ON u.id = uvc.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.userid
LEFT JOIN user_badges ub      ON u.id = ub.userid
LEFT JOIN user_tags ut        ON u.id = ut.userid
LEFT JOIN user_postlinks upL  ON u.id = upL.userid
LEFT JOIN user_posthistory upH ON u.id = upH.userid
ORDER BY u.reputation DESC
LIMIT 100
