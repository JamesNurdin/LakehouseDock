WITH
    user_base AS (
        SELECT id AS userid, reputation
        FROM users
    ),
    user_posts AS (
        SELECT owneruserid AS userid,
               COUNT(*) AS post_count,
               SUM(viewcount) AS total_viewcount,
               SUM(score) AS total_score,
               AVG(score) AS avg_score
        FROM posts
        GROUP BY owneruserid
    ),
    user_edits AS (
        SELECT lasteditoruserid AS userid,
               COUNT(*) AS edit_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    user_comments AS (
        SELECT userid,
               COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT userid,
               COUNT(*) AS vote_count,
               SUM(COALESCE(bountyamount, 0)) AS total_bounty_amount
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT userid,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posthistory AS (
        SELECT userid,
               COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    user_postlinks AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT pl.id) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_tag_counts AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.userid,
    ub.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_score, 0) AS total_score,
    COALESCE(up.avg_score, 0) AS avg_score,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(ubd.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(upk.postlink_count, 0) AS postlink_count,
    COALESCE(utc.distinct_tag_count, 0) AS distinct_tag_count
FROM user_base ub
LEFT JOIN user_posts up ON ub.userid = up.userid
LEFT JOIN user_edits ue ON ub.userid = ue.userid
LEFT JOIN user_comments uc ON ub.userid = uc.userid
LEFT JOIN user_votes uv ON ub.userid = uv.userid
LEFT JOIN user_badges ubd ON ub.userid = ubd.userid
LEFT JOIN user_posthistory uph ON ub.userid = uph.userid
LEFT JOIN user_postlinks upk ON ub.userid = upk.userid
LEFT JOIN user_tag_counts utc ON ub.userid = utc.userid
ORDER BY ub.reputation DESC
LIMIT 100
