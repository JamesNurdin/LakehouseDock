WITH tag_aggregates AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.viewcount) AS total_views,
        AVG(p.score) AS avg_post_score,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.score) AS avg_comment_score,
        COUNT(DISTINCT v.id) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(v.bountyamount) AS total_bounty_amount,
        COUNT(DISTINCT u.id) AS distinct_owner_user_count,
        COUNT(DISTINCT b.id) AS badge_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    LEFT JOIN comments c ON c.postid = p.id
    LEFT JOIN votes v ON v.postid = p.id
    LEFT JOIN users u ON p.owneruserid = u.id
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY t.id
)
SELECT
    tag_id,
    post_count,
    total_views,
    avg_post_score,
    comment_count,
    avg_comment_score,
    vote_count,
    upvote_count,
    total_bounty_amount,
    distinct_owner_user_count,
    badge_count
FROM tag_aggregates
ORDER BY post_count DESC
LIMIT 10
