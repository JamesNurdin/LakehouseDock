WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS post_score_sum,
            AVG(score) AS post_score_avg,
            SUM(viewcount) AS post_view_sum,
            SUM(answercount) AS post_answer_sum,
            SUM(commentcount) AS post_comment_sum,
            SUM(favoritecount) AS post_favorite_sum
        FROM posts
        GROUP BY owneruserid
    ),
    user_edits AS (
        SELECT
            lasteditoruserid AS userid,
            COUNT(*) AS edit_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            SUM(score) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_given,
            SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_given
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory_by_user AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_by_user_count
        FROM posthistory
        GROUP BY userid
    ),
    user_posthistory_on_posts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS posthistory_on_posts_count
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(up.post_answer_sum, 0) AS post_answer_sum,
    COALESCE(up.post_comment_sum, 0) AS post_comment_sum,
    COALESCE(up.post_favorite_sum, 0) AS post_favorite_sum,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.upvote_given, 0) AS upvote_given,
    COALESCE(uv.downvote_given, 0) AS downvote_given,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ulp.postlink_count, 0) AS postlink_count,
    COALESCE(upb.posthistory_by_user_count, 0) AS posthistory_by_user_count,
    COALESCE(uph.posthistory_on_posts_count, 0) AS posthistory_on_posts_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_postlinks ulp ON ulp.userid = u.id
LEFT JOIN user_posthistory_by_user upb ON upb.userid = u.id
LEFT JOIN user_posthistory_on_posts uph ON uph.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
