WITH
    user_base AS (
        SELECT id AS user_id,
               reputation
        FROM users
    ),
    post_metrics AS (
        SELECT owneruserid AS user_id,
               COUNT(*) AS post_count,
               COALESCE(SUM(score), 0) AS total_post_score,
               COALESCE(SUM(viewcount), 0) AS total_post_views
        FROM posts
        GROUP BY owneruserid
    ),
    comment_made_metrics AS (
        SELECT userid AS user_id,
               COUNT(*) AS comment_count_made
        FROM comments
        GROUP BY userid
    ),
    comment_received_metrics AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS comment_count_received
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    vote_given_metrics AS (
        SELECT userid AS user_id,
               COUNT(*) AS vote_count_given
        FROM votes
        GROUP BY userid
    ),
    vote_received_metrics AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS vote_count_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badge_metrics AS (
        SELECT userid AS user_id,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    posthistory_made_metrics AS (
        SELECT userid AS user_id,
               COUNT(*) AS posthistory_count_made
        FROM posthistory
        GROUP BY userid
    ),
    posthistory_on_user_posts_metrics AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS posthistory_count_on_user_posts
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    tag_on_user_posts_metrics AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS tag_count_on_user_posts
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlink_on_user_posts_metrics AS (
        SELECT pl_user.owner_user_id AS user_id,
               COUNT(*) AS postlink_count_on_user_posts
        FROM (
            SELECT p.owneruserid AS owner_user_id
            FROM postlinks pl
            JOIN posts p ON pl.postid = p.id
            UNION ALL
            SELECT p.owneruserid AS owner_user_id
            FROM postlinks pl
            JOIN posts p ON pl.relatedpostid = p.id
        ) pl_user
        GROUP BY pl_user.owner_user_id
    )
SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.total_post_score, 0) AS total_post_score,
    COALESCE(pm.total_post_views, 0) AS total_post_views,
    COALESCE(cm.comment_count_made, 0) AS comment_count_made,
    COALESCE(cr.comment_count_received, 0) AS comment_count_received,
    COALESCE(vg.vote_count_given, 0) AS vote_count_given,
    COALESCE(vr.vote_count_received, 0) AS vote_count_received,
    COALESCE(bm.badge_count, 0) AS badge_count,
    COALESCE(phm.posthistory_count_made, 0) AS posthistory_count_made,
    COALESCE(pho.posthistory_count_on_user_posts, 0) AS posthistory_count_on_user_posts,
    COALESCE(tpm.tag_count_on_user_posts, 0) AS tag_count_on_user_posts,
    COALESCE(plm.postlink_count_on_user_posts, 0) AS postlink_count_on_user_posts
FROM user_base ub
LEFT JOIN post_metrics pm ON ub.user_id = pm.user_id
LEFT JOIN comment_made_metrics cm ON ub.user_id = cm.user_id
LEFT JOIN comment_received_metrics cr ON ub.user_id = cr.user_id
LEFT JOIN vote_given_metrics vg ON ub.user_id = vg.user_id
LEFT JOIN vote_received_metrics vr ON ub.user_id = vr.user_id
LEFT JOIN badge_metrics bm ON ub.user_id = bm.user_id
LEFT JOIN posthistory_made_metrics phm ON ub.user_id = phm.user_id
LEFT JOIN posthistory_on_user_posts_metrics pho ON ub.user_id = pho.user_id
LEFT JOIN tag_on_user_posts_metrics tpm ON ub.user_id = tpm.user_id
LEFT JOIN postlink_on_user_posts_metrics plm ON ub.user_id = plm.user_id
ORDER BY ub.reputation DESC
LIMIT 10
