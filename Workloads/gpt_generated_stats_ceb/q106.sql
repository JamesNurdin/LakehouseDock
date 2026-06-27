WITH tag_excerpt AS (
    SELECT
        t.id AS tag_id,
        t.count AS tag_total_posts,
        p.id AS post_id,
        p.score AS post_score,
        p.viewcount,
        p.creationdate,
        p.owneruserid,
        p.lasteditoruserid
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
),
post_comment_agg AS (
    SELECT
        c.postid,
        COUNT(c.id) AS comment_cnt,
        COALESCE(SUM(c.score), 0) AS comment_score_sum,
        CASE WHEN COUNT(c.id) = 0 THEN NULL ELSE AVG(c.score) END AS comment_score_avg
    FROM comments c
    GROUP BY c.postid
),
post_link_agg AS (
    SELECT
        p.id AS post_id,
        COUNT(pl.id) AS link_cnt
    FROM posts p
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.id
)
SELECT
    te.tag_id,
    te.tag_total_posts,
    te.post_id,
    te.post_score,
    te.viewcount,
    te.creationdate,
    owner.id AS owner_user_id,
    owner.reputation AS owner_reputation,
    editor.id AS last_editor_user_id,
    editor.reputation AS last_editor_reputation,
    COALESCE(pc.comment_cnt, 0) AS comment_cnt,
    COALESCE(pc.comment_score_sum, 0) AS comment_score_sum,
    pc.comment_score_avg,
    COALESCE(pl.link_cnt, 0) AS related_link_cnt
FROM tag_excerpt te
LEFT JOIN post_comment_agg pc ON pc.postid = te.post_id
LEFT JOIN post_link_agg pl ON pl.post_id = te.post_id
JOIN users owner ON owner.id = te.owneruserid
JOIN users editor ON editor.id = te.lasteditoruserid
ORDER BY comment_score_sum DESC
LIMIT 20
