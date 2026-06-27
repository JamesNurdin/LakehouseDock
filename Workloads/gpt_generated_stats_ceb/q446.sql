WITH post_metrics AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_view_count
    FROM posts p
    GROUP BY p.owneruserid
),
comment_metrics AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
vote_metrics AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_cast_count,
        COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS upvote_cast_count,
        COUNT(CASE WHEN v.votetypeid = 3 THEN 1 END) AS downvote_cast_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount
    FROM votes v
    GROUP BY v.userid
),
badge_metrics AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
tag_metrics AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_excerpt_count
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
posthistory_metrics AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS post_history_count
    FROM posthistory ph
    GROUP BY ph.userid
),
postlinks_metrics AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.total_post_score, 0) AS total_post_score,
    COALESCE(pm.total_view_count, 0) AS total_view_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.total_comment_score, 0) AS total_comment_score,
    COALESCE(vm.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vm.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(vm.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(vm.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(bm.badge_count, 0) AS badge_count,
    COALESCE(tm.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(phm.post_history_count, 0) AS post_history_count,
    COALESCE(plm.post_link_count, 0) AS post_link_count
FROM users u
LEFT JOIN post_metrics pm ON pm.user_id = u.id
LEFT JOIN comment_metrics cm ON cm.user_id = u.id
LEFT JOIN vote_metrics vm ON vm.user_id = u.id
LEFT JOIN badge_metrics bm ON bm.user_id = u.id
LEFT JOIN tag_metrics tm ON tm.user_id = u.id
LEFT JOIN posthistory_metrics phm ON phm.user_id = u.id
LEFT JOIN postlinks_metrics plm ON plm.user_id = u.id
ORDER BY post_count DESC
LIMIT 100
