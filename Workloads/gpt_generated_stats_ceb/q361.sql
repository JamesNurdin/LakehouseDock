WITH user_post_agg AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS total_posts,
        AVG(p.score) AS avg_post_score,
        SUM(p.score) AS sum_post_score,
        COALESCE(SUM(cs.comment_cnt), 0) AS total_comments_received,
        CASE WHEN SUM(cs.comment_cnt) > 0
            THEN SUM(cs.sum_comment_score) / NULLIF(SUM(cs.comment_cnt), 0)
        END AS avg_comment_score_on_posts,
        COALESCE(SUM(plc.link_cnt), 0) AS total_post_links
    FROM posts p
    JOIN users u ON p.owneruserid = u.id
    LEFT JOIN (
        SELECT
            c.postid,
            COUNT(*) AS comment_cnt,
            SUM(c.score) AS sum_comment_score
        FROM comments c
        GROUP BY c.postid
    ) cs ON cs.postid = p.id
    LEFT JOIN (
        SELECT
            post_id,
            COUNT(*) AS link_cnt
        FROM (
            SELECT pl.postid AS post_id FROM postlinks pl
            UNION ALL
            SELECT pl.relatedpostid AS post_id FROM postlinks pl
        ) sub
        GROUP BY post_id
    ) plc ON plc.post_id = p.id
    GROUP BY u.id, u.reputation
)
SELECT
    user_id,
    reputation,
    total_posts,
    avg_post_score,
    sum_post_score,
    total_comments_received,
    avg_comment_score_on_posts,
    total_post_links,
    RANK() OVER (ORDER BY total_posts DESC) AS post_rank
FROM user_post_agg
ORDER BY total_posts DESC
LIMIT 10
