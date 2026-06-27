WITH
    user_base AS (
        SELECT id AS user_id,
               reputation
        FROM users
    ),
    posts_agg AS (
        SELECT owneruserid AS user_id,
               COUNT(*) AS post_count,
               COALESCE(SUM(score), 0) AS total_post_score,
               COALESCE(AVG(score), 0) AS avg_post_score,
               COALESCE(SUM(viewcount), 0) AS total_view_count,
               COALESCE(SUM(favoritecount), 0) AS total_favorite_count
        FROM posts
        GROUP BY owneruserid
    ),
    comments_agg AS (
        SELECT userid AS user_id,
               COUNT(*) AS comment_count,
               COALESCE(SUM(score), 0) AS total_comment_score,
               COALESCE(AVG(score), 0) AS avg_comment_score
        FROM comments
        GROUP BY userid
    ),
    votes_cast_agg AS (
        SELECT userid AS user_id,
               COUNT(*) AS votes_cast_count,
               SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
               SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM votes
        GROUP BY userid
    ),
    votes_received_agg AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS votes_received_count,
               SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
               SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badges_agg AS (
        SELECT userid AS user_id,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    posthistory_agg AS (
        SELECT userid AS user_id,
               COUNT(*) AS history_count
        FROM posthistory
        GROUP BY userid
    ),
    tags_agg AS (
        SELECT p.owneruserid AS user_id,
               COALESCE(SUM(t."count"), 0) AS total_tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(pa.post_count, 0)               AS post_count,
    COALESCE(pa.total_post_score, 0)         AS total_post_score,
    COALESCE(pa.avg_post_score, 0)           AS avg_post_score,
    COALESCE(pa.total_view_count, 0)         AS total_view_count,
    COALESCE(pa.total_favorite_count, 0)    AS total_favorite_count,
    COALESCE(ca.comment_count, 0)            AS comment_count,
    COALESCE(ca.total_comment_score, 0)     AS total_comment_score,
    COALESCE(ca.avg_comment_score, 0)       AS avg_comment_score,
    COALESCE(vc.votes_cast_count, 0)        AS votes_cast_count,
    COALESCE(vc.upvotes_cast, 0)            AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0)          AS downvotes_cast,
    COALESCE(vr.votes_received_count, 0)    AS votes_received_count,
    COALESCE(vr.upvotes_received, 0)        AS upvotes_received,
    COALESCE(vr.downvotes_received, 0)      AS downvotes_received,
    COALESCE(ba.badge_count, 0)             AS badge_count,
    COALESCE(ph.history_count, 0)           AS post_history_count,
    COALESCE(ta.total_tag_count, 0)         AS total_tag_count
FROM user_base ub
LEFT JOIN posts_agg pa          ON ub.user_id = pa.user_id
LEFT JOIN comments_agg ca       ON ub.user_id = ca.user_id
LEFT JOIN votes_cast_agg vc     ON ub.user_id = vc.user_id
LEFT JOIN votes_received_agg vr ON ub.user_id = vr.user_id
LEFT JOIN badges_agg ba         ON ub.user_id = ba.user_id
LEFT JOIN posthistory_agg ph    ON ub.user_id = ph.user_id
LEFT JOIN tags_agg ta           ON ub.user_id = ta.user_id
ORDER BY total_post_score DESC
LIMIT 100
