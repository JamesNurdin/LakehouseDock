WITH
    user_posts AS (
        SELECT owneruserid,
               COUNT(*) AS post_count,
               SUM(score) AS total_score,
               SUM(answercount) AS total_answers,
               SUM(commentcount) AS total_comments,
               SUM(viewcount) AS total_views,
               SUM(favoritecount) AS total_favorites
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
    user_votes AS (
        SELECT userid,
               COUNT(*) AS vote_count,
               SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
               SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
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
    user_tag_counts AS (
        SELECT p.owneruserid,
               COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT p.owneruserid,
               COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    up.owneruserid,
    up.post_count,
    up.total_score,
    up.total_answers,
    up.total_comments,
    up.total_views,
    up.total_favorites,
    uc.comment_count,
    uc.comment_score_sum,
    uv.vote_count,
    uv.upvote_count,
    uv.downvote_count,
    uv.total_bounty_amount,
    ub.badge_count,
    uph.posthistory_count,
    utc.distinct_tag_count,
    upl.postlink_count
FROM users u
LEFT JOIN user_posts up ON u.id = up.owneruserid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes uv ON u.id = uv.userid
LEFT JOIN user_badges ub ON u.id = ub.userid
LEFT JOIN user_posthistory uph ON u.id = uph.userid
LEFT JOIN user_tag_counts utc ON u.id = utc.owneruserid
LEFT JOIN user_postlinks upl ON u.id = upl.owneruserid
ORDER BY up.post_count DESC NULLS LAST
LIMIT 100
