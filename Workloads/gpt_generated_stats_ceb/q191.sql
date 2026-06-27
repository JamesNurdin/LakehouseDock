WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            AVG(score) AS avg_post_score,
            SUM(viewcount) AS total_post_views,
            SUM(answercount) AS total_answers,
            SUM(commentcount) AS total_post_comments,
            SUM(favoritecount) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            AVG(score) AS avg_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
            SUM(bountyamount) AS total_bounty
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS edit_count
        FROM posthistory
        GROUP BY userid
    ),
    user_last_edits AS (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(*) AS last_edit_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    user_tag_counts AS (
        SELECT
            p.owneruserid AS user_id,
            SUM(t.count) AS total_tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
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
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_post_views, 0) AS total_post_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_post_comments, 0) AS total_post_comments,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.upvote_count, 0) AS upvote_count,
    COALESCE(uv.downvote_count, 0) AS downvote_count,
    COALESCE(uv.total_bounty, 0) AS total_bounty,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ul.last_edit_count, 0) AS last_edit_count,
    COALESCE(ut.total_tag_count, 0) AS total_tag_count,
    COALESCE(plc.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_last_edits ul ON ul.user_id = u.id
LEFT JOIN user_tag_counts ut ON ut.user_id = u.id
LEFT JOIN user_postlinks plc ON plc.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
