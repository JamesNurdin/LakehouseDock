WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(CASE WHEN posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
            SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_view_count,
            SUM(answercount) AS total_answer_count,
            SUM(commentcount) AS total_comment_count,
            SUM(favoritecount) AS total_favorite_count
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast,
            SUM(CASE WHEN votetypeid = 3 THEN bountyamount ELSE 0 END) AS bounty_given
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received,
            SUM(CASE WHEN v.votetypeid = 3 THEN v.bountyamount ELSE 0 END) AS bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.question_count, 0) AS question_count,
    COALESCE(up.answer_count, 0) AS answer_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.upvote_cast, 0) AS upvotes_cast,
    COALESCE(uvc.downvote_cast, 0) AS downvotes_cast,
    COALESCE(uvc.bounty_given, 0) AS bounty_given,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvote_received, 0) AS upvotes_received,
    COALESCE(uvr.downvote_received, 0) AS downvotes_received,
    COALESCE(uvr.bounty_received, 0) AS bounty_received,
    COALESCE(ub.badge_count, 0) AS badge_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
