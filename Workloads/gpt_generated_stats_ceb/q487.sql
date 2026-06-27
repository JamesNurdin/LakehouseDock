WITH
    user_posts AS (
        SELECT
            owneruserid,
            COUNT(*) AS post_count,
            SUM(score) AS post_score_sum,
            SUM(viewcount) AS post_view_sum,
            SUM(answercount) AS answer_count_sum,
            SUM(commentcount) AS comment_count_sum,
            SUM(favoritecount) AS favorite_count_sum
        FROM posts
        GROUP BY owneruserid
    ),
    user_edits AS (
        SELECT
            lasteditoruserid,
            COUNT(*) AS edited_post_count,
            SUM(score) AS edited_post_score_sum
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
    user_votes_cast AS (
        SELECT
            userid,
            COUNT(*) AS votes_cast,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS votes_received,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posthistory AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(up.answer_count_sum, 0) AS answer_count_sum,
    COALESCE(up.comment_count_sum, 0) AS comment_count_sum,
    COALESCE(up.favorite_count_sum, 0) AS favorite_count_sum,
    COALESCE(ue.edited_post_count, 0) AS edited_post_count,
    COALESCE(ue.edited_post_score_sum, 0) AS edited_post_score_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.upvote_cast, 0) AS upvote_cast,
    COALESCE(vc.downvote_cast, 0) AS downvote_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.upvote_received, 0) AS upvote_received,
    COALESCE(vr.downvote_received, 0) AS downvote_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(tg.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_edits ue ON ue.lasteditoruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast vc ON vc.userid = u.id
LEFT JOIN user_votes_received vr ON vr.owneruserid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_posthistory ph ON ph.userid = u.id
LEFT JOIN user_tags tg ON tg.owneruserid = u.id
ORDER BY u.reputation DESC
LIMIT 20
