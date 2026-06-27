WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments_on_posts,
        SUM(p.favoritecount) AS total_favorites
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(c.score) AS total_comment_score,
        AVG(c.score) AS avg_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS total_bounty_amount,
        COUNT(DISTINCT v.postid) AS distinct_posts_voted
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
user_edits AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS edit_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_owned_links AS (
    SELECT
        p.owneruserid AS user_id,
        SUM(COALESCE(l.link_count, 0)) AS total_links_created
    FROM posts p
    LEFT JOIN (
        SELECT
            pl.postid,
            COUNT(*) AS link_count
        FROM postlinks pl
        GROUP BY pl.postid
    ) l ON p.id = l.postid
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(uv.distinct_posts_voted, 0) AS distinct_posts_voted,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ul.total_links_created, 0) AS total_links_created,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN user_comments uc ON u.id = uc.user_id
LEFT JOIN user_votes uv ON u.id = uv.user_id
LEFT JOIN user_badges ub ON u.id = ub.user_id
LEFT JOIN user_edits ue ON u.id = ue.user_id
LEFT JOIN user_owned_links ul ON u.id = ul.user_id
LEFT JOIN user_tags ut ON u.id = ut.user_id
ORDER BY u.reputation DESC
LIMIT 100
