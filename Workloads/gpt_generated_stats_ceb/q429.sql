WITH tag_agg AS (
    SELECT
        t.id,
        t.count,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_viewcount,
        AVG(p.answercount) AS avg_answercount
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    WHERE p.posttypeid = 1
    GROUP BY t.id, t.count
    HAVING t.count > 10
)
SELECT
    id AS tag_id,
    count AS tag_use_count,
    avg_score,
    total_viewcount,
    avg_answercount,
    RANK() OVER (ORDER BY count DESC) AS tag_rank,
    SUM(total_viewcount) OVER (
        ORDER BY count DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_views
FROM tag_agg
ORDER BY count DESC
LIMIT 20
