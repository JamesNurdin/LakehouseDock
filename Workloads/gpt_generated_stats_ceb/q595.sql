WITH
    user_info AS (
        SELECT id AS userid,
               reputation,
               creationdate,
               views,
               upvotes,
               downvotes
        FROM users
    ),
    user_posts AS (
        SELECT owneruserid AS userid,
               COUNT(*) AS post_count,
               COALESCE(SUM(score), 0) AS post_score,
               COALESCE(SUM(viewcount), 0) AS post_views,
               COALESCE(SUM(answercount), 0) AS total_answers
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
               COUNT(*) AS comment_count,
               COALESCE(SUM(score), 0) AS comment_score
        FROM comments
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
    user_votes_cast AS (
        SELECT userid,
               COUNT(*) AS votes_cast,
               COALESCE(SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
               COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS votes_received,
               COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_received,
               COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ui.userid,
    ui.reputation,
    ui.creationdate,
    ui.views,
    ui.upvotes,
    ui.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score, 0) AS post_score,
    COALESCE(up.post_views, 0) AS post_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score, 0) AS comment_score,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received
FROM user_info ui
LEFT JOIN user_posts up ON ui.userid = up.userid
LEFT JOIN user_edits ue ON ui.userid = ue.userid
LEFT JOIN user_comments uc ON ui.userid = uc.userid
LEFT JOIN user_badges ub ON ui.userid = ub.userid
LEFT JOIN user_posthistory uph ON ui.userid = uph.userid
LEFT JOIN user_votes_cast uvc ON ui.userid = uvc.userid
LEFT JOIN user_votes_received uvr ON ui.userid = uvr.userid
ORDER BY post_score DESC
LIMIT 100
