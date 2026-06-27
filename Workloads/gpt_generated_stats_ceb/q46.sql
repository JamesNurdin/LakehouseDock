WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS post_score_sum,
            SUM(p.viewcount) AS post_view_sum
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(c.score) AS comment_score_sum
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS vote_count,
            SUM(v.bountyamount) AS total_bounty
        FROM votes v
        GROUP BY v.userid
    ),
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tag_count,
            SUM(t.count) AS tag_total
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS edited_posts
        FROM posts p
        WHERE p.lasteditoruserid IS NOT NULL
        GROUP BY p.lasteditoruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS total_post_score,
    COALESCE(up.post_view_sum, 0) AS total_post_views,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS total_comment_score,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.total_bounty, 0) AS total_bounty_amount,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(pl.postlink_count, 0) AS postlink_count,
    COALESCE(tg.tag_count, 0) AS tag_count,
    COALESCE(tg.tag_total, 0) AS tag_total,
    COALESCE(ed.edited_posts, 0) AS edited_posts,
    CASE
        WHEN COALESCE(up.post_count, 0) = 0 THEN NULL
        ELSE COALESCE(up.post_score_sum, 0) * 1.0 / COALESCE(up.post_count, 0)
    END AS avg_post_score
FROM users u
LEFT JOIN user_posts up      ON u.id = up.user_id
LEFT JOIN user_comments uc   ON u.id = uc.user_id
LEFT JOIN user_votes uv      ON u.id = uv.user_id
LEFT JOIN user_badges ub     ON u.id = ub.user_id
LEFT JOIN user_posthistory uph ON u.id = uph.user_id
LEFT JOIN user_postlinks pl  ON u.id = pl.user_id
LEFT JOIN user_tags tg       ON u.id = tg.user_id
LEFT JOIN user_edits ed      ON u.id = ed.user_id
ORDER BY u.reputation DESC
LIMIT 100
