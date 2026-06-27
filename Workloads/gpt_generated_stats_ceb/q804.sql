WITH tag_stats AS (
    SELECT
        p.id AS post_id,
        COUNT(t.id) AS tag_count,
        COALESCE(SUM(t.count), 0) AS tag_sum_count
    FROM posts p
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.id
),
history_stats AS (
    SELECT
        p.id AS post_id,
        COUNT(ph.id) AS history_event_count
    FROM posts p
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    GROUP BY p.id
)
SELECT
    p.id,
    p.creationdate,
    p.score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    ts.tag_count,
    ts.tag_sum_count,
    hs.history_event_count,
    (p.score + p.viewcount) / (1 + hs.history_event_count) AS weighted_score
FROM posts p
LEFT JOIN tag_stats ts
    ON ts.post_id = p.id
LEFT JOIN history_stats hs
    ON hs.post_id = p.id
WHERE p.creationdate >= TIMESTAMP '2023-01-01 00:00:00 UTC'
ORDER BY weighted_score DESC
LIMIT 10
