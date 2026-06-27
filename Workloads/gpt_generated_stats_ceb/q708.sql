WITH
    user_posts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score,
            SUM(p.answercount) AS total_answers,
            SUM(p.commentcount) AS total_comments_on_posts,
            SUM(p.favoritecount) AS total_favorites
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT
            c.userid,
            COUNT(*) AS comment_count
        FROM comments c
        GROUP BY c.userid
    ),
    user_badges AS (
        SELECT
            b.userid,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_votes_cast AS (
        SELECT
            v.userid,
            COUNT(*) AS votes_cast,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes_cast,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS votes_received,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes_received,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.up_votes_cast, 0) AS up_votes_cast,
    COALESCE(uvc.down_votes_cast, 0) AS down_votes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.up_votes_received, 0) AS up_votes_received,
    COALESCE(uvr.down_votes_received, 0) AS down_votes_received,
    RANK() OVER (ORDER BY COALESCE(up.total_post_score, 0) DESC) AS post_score_rank
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
ORDER BY u.reputation DESC
LIMIT 10
