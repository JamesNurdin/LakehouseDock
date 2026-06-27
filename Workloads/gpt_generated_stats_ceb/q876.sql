WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        COUNT(CASE WHEN p.posttypeid = 1 THEN 1 END) AS question_count,
        COUNT(CASE WHEN p.posttypeid = 2 THEN 1 END) AS answer_count,
        SUM(p.score) AS total_post_score
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_cast_count
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
        COUNT(*) AS post_edit_count
    FROM posthistory ph
    GROUP BY ph.userid
),
post_links AS (
    SELECT
        pl.postid AS post_id,
        COUNT(*) AS link_count
    FROM postlinks pl
    GROUP BY pl.postid
),
user_post_links AS (
    SELECT
        p.owneruserid AS user_id,
        COALESCE(SUM(pl.link_count), 0) AS post_link_count
    FROM posts p
    LEFT JOIN post_links pl ON pl.post_id = p.id
    GROUP BY p.owneruserid
),
user_tag_excerpts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS tag_excerpt_post_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.question_count, 0) AS question_count,
    COALESCE(up.answer_count, 0) AS answer_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.post_edit_count, 0) AS post_edit_count,
    COALESCE(upl.post_link_count, 0) AS post_link_count,
    COALESCE(ut.tag_excerpt_post_count, 0) AS tag_excerpt_post_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_post_links upl ON upl.user_id = u.id
LEFT JOIN user_tag_excerpts ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 20
