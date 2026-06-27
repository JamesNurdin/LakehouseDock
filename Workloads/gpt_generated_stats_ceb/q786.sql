WITH
    user_posts_agg AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            COALESCE(SUM(score), 0) AS total_post_score,
            COALESCE(AVG(score), 0) AS avg_post_score,
            COALESCE(SUM(viewcount), 0) AS total_viewcount,
            COALESCE(SUM(favoritecount), 0) AS total_favoritecount,
            COALESCE(SUM(answercount), 0) AS total_answercount,
            COALESCE(SUM(commentcount), 0) AS total_commentcount
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            COALESCE(SUM(score), 0) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS vote_cast_count,
            COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
            COALESCE(SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS vote_received_count,
            COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
            COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posthistory_by_user_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_by_user_count,
            COALESCE(SUM(CASE WHEN posthistorytypeid = 1 THEN 1 ELSE 0 END), 0) AS post_edits_by_user,
            COALESCE(SUM(CASE WHEN posthistorytypeid = 2 THEN 1 ELSE 0 END), 0) AS post_closures_by_user
        FROM posthistory
        GROUP BY userid
    ),
    user_posthistory_on_posts_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS posthistory_on_post_count
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    user_last_edits_agg AS (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(*) AS last_editor_count
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(p.total_answercount, 0) AS total_answercount,
    COALESCE(p.total_commentcount, 0) AS total_commentcount,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.vote_received_count, 0) AS vote_received_count,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(phu.posthistory_by_user_count, 0) AS posthistory_by_user_count,
    COALESCE(phu.post_edits_by_user, 0) AS post_edits_by_user,
    COALESCE(phu.post_closures_by_user, 0) AS post_closures_by_user,
    COALESCE(pho.posthistory_on_post_count, 0) AS posthistory_on_post_count,
    COALESCE(le.last_editor_count, 0) AS last_editor_count
FROM users u
LEFT JOIN user_posts_agg p ON p.user_id = u.id
LEFT JOIN user_comments_agg c ON c.user_id = u.id
LEFT JOIN user_votes_cast_agg vc ON vc.user_id = u.id
LEFT JOIN user_votes_received_agg vr ON vr.user_id = u.id
LEFT JOIN user_badges_agg b ON b.user_id = u.id
LEFT JOIN user_posthistory_by_user_agg phu ON phu.user_id = u.id
LEFT JOIN user_posthistory_on_posts_agg pho ON pho.user_id = u.id
LEFT JOIN user_last_edits_agg le ON le.user_id = u.id
WHERE u.reputation >= 1000
ORDER BY total_post_score DESC
LIMIT 50
