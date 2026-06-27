WITH
    user_posts_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(p.id) AS post_count,
            SUM(p.score) AS post_score_sum,
            AVG(p.score) AS post_score_avg,
            SUM(p.viewcount) AS post_view_sum
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments_agg AS (
        SELECT
            c.userid AS user_id,
            COUNT(c.id) AS comment_count,
            SUM(c.score) AS comment_score_sum,
            AVG(c.score) AS comment_score_avg
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes_agg AS (
        SELECT
            v.userid AS user_id,
            COUNT(v.id) AS vote_count,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast,
            COALESCE(SUM(v.bountyamount), 0) AS bounty_total
        FROM votes v
        GROUP BY v.userid
    ),
    user_badges_agg AS (
        SELECT
            b.userid AS user_id,
            COUNT(b.id) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_posthistory_agg AS (
        SELECT
            ph.userid AS user_id,
            COUNT(ph.id) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_last_editor_posts_agg AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(p.id) AS last_editor_post_count
        FROM posts p
        WHERE p.lasteditoruserid IS NOT NULL
        GROUP BY p.lasteditoruserid
    ),
    user_postlinks_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
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
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uc.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.upvote_cast, 0) AS upvote_cast,
    COALESCE(uv.downvote_cast, 0) AS downvote_cast,
    COALESCE(uv.bounty_total, 0) AS bounty_total,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ul.last_editor_post_count, 0) AS last_editor_post_count,
    COALESCE(ulinks.postlink_count, 0) AS postlink_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts_agg up ON up.user_id = u.id
LEFT JOIN user_comments_agg uc ON uc.user_id = u.id
LEFT JOIN user_votes_agg uv ON uv.user_id = u.id
LEFT JOIN user_badges_agg ub ON ub.user_id = u.id
LEFT JOIN user_posthistory_agg uph ON uph.user_id = u.id
LEFT JOIN user_last_editor_posts_agg ul ON ul.user_id = u.id
LEFT JOIN user_postlinks_agg ulinks ON ulinks.user_id = u.id
LEFT JOIN user_tags_agg ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
