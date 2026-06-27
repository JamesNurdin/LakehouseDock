WITH tag_posts AS (
    SELECT
        t.id AS tag_id,
        p.id AS post_id,
        p.viewcount,
        p.score,
        p.owneruserid,
        u.reputation AS owner_reputation
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
    JOIN users u
        ON p.owneruserid = u.id
),
post_comments AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_cnt
    FROM comments c
    GROUP BY c.postid
),
post_votes AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_cnt
    FROM votes v
    GROUP BY v.postid
)
SELECT
    tp.tag_id,
    COUNT(DISTINCT tp.post_id) AS post_cnt,
    SUM(tp.viewcount) AS total_viewcount,
    AVG(tp.score) AS avg_score,
    COUNT(DISTINCT tp.owneruserid) AS distinct_owner_cnt,
    SUM(tp.owner_reputation) AS total_owner_reputation,
    COALESCE(SUM(pc.comment_cnt), 0) AS total_comment_cnt,
    COALESCE(SUM(pv.vote_cnt), 0) AS total_vote_cnt
FROM tag_posts tp
LEFT JOIN post_comments pc
    ON tp.post_id = pc.post_id
LEFT JOIN post_votes pv
    ON tp.post_id = pv.post_id
GROUP BY tp.tag_id
ORDER BY total_viewcount DESC
LIMIT 10
