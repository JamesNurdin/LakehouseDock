WITH
    user_badges AS (
        SELECT userid,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posts AS (
        SELECT owneruserid,
               COUNT(*) AS post_count,
               SUM(score) AS total_post_score,
               SUM(viewcount) AS total_views,
               SUM(answercount) AS total_answers,
               SUM(commentcount) AS total_comments,
               SUM(favoritecount) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT userid,
               COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT userid,
               COUNT(*) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT posts.owneruserid AS user_id,
               COUNT(*) AS votes_received
        FROM votes
        JOIN posts ON votes.postid = posts.id
        GROUP BY posts.owneruserid
    ),
    user_posthistory AS (
        SELECT userid,
               COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    user_tags AS (
        SELECT posts.owneruserid AS user_id,
               COUNT(*) AS tag_count
        FROM tags
        JOIN posts ON tags.excerptpostid = posts.id
        GROUP BY posts.owneruserid
    ),
    user_postlinks AS (
        SELECT posts.owneruserid AS user_id,
               COUNT(*) AS postlink_count
        FROM postlinks
        JOIN posts ON postlinks.postid = posts.id
        GROUP BY posts.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments, 0) AS total_comments,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(ulp.postlink_count, 0) AS postlink_count,
    (u.reputation
        + COALESCE(ub.badge_count, 0) * 10
        + COALESCE(up.post_count, 0) * 5
        + COALESCE(uc.comment_count, 0) * 2
        + COALESCE(uvc.votes_cast, 0)
        + COALESCE(uvr.votes_received, 0) * 2
        + COALESCE(ut.tag_count, 0) * 3) AS engagement_score
FROM users u
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_postlinks ulp ON ulp.user_id = u.id
ORDER BY engagement_score DESC
LIMIT 100
