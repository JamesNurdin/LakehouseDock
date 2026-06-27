WITH post_comment_counts AS (
    SELECT
        p.id AS post_id,
        COUNT(c.id) AS comment_cnt
    FROM posts p
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY p.id
),
post_vote_counts AS (
    SELECT
        p.id AS post_id,
        COUNT(v.id) AS vote_cnt
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY p.id
),
post_tag_counts AS (
    SELECT
        p.id AS post_id,
        COUNT(t.id) AS tag_cnt
    FROM posts p
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    COUNT(p.id) AS post_cnt,
    COALESCE(SUM(p.score), 0) AS total_score,
    COALESCE(AVG(p.score), 0) AS avg_score,
    COALESCE(SUM(pc.comment_cnt), 0) AS total_comments,
    COALESCE(SUM(pv.vote_cnt), 0) AS total_votes,
    COALESCE(SUM(pt.tag_cnt), 0) AS total_tags
FROM users u
LEFT JOIN posts p
    ON p.owneruserid = u.id
LEFT JOIN post_comment_counts pc
    ON pc.post_id = p.id
LEFT JOIN post_vote_counts pv
    ON pv.post_id = p.id
LEFT JOIN post_tag_counts pt
    ON pt.post_id = p.id
GROUP BY u.id, u.reputation
ORDER BY total_score DESC
LIMIT 50
