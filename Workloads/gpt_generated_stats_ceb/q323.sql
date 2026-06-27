WITH owner_stats AS (
    SELECT
        p.owneruserid,
        COUNT(DISTINCT p.id) AS post_cnt,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        COUNT(c.id) AS comment_cnt,
        SUM(c.score) AS total_comment_score,
        AVG(c.score) AS avg_comment_score
    FROM posts p
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY p.owneruserid
),
ranked_owners AS (
    SELECT
        owneruserid,
        post_cnt,
        total_post_score,
        avg_post_score,
        comment_cnt,
        total_comment_score,
        avg_comment_score,
        RANK() OVER (ORDER BY avg_comment_score DESC) AS owner_rank
    FROM owner_stats
    WHERE comment_cnt > 0
)
SELECT
    owneruserid,
    post_cnt,
    total_post_score,
    avg_post_score,
    comment_cnt,
    total_comment_score,
    avg_comment_score,
    owner_rank
FROM ranked_owners
WHERE owner_rank <= 10
ORDER BY owner_rank
