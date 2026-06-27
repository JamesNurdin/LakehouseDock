WITH tag_post_metrics AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments,
        COUNT(DISTINCT u.id) AS distinct_owner_count,
        AVG(u.reputation) AS avg_owner_reputation,
        COUNT(DISTINCT b.id) AS badge_count,
        SUM(v.bountyamount) AS total_bounty_amount,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(c.score) AS total_comment_score
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN users u ON p.owneruserid = u.id
    LEFT JOIN badges b ON b.userid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY t.id
)
SELECT
    tag_id,
    post_count,
    avg_post_score,
    total_views,
    total_answers,
    total_comments,
    distinct_owner_count,
    avg_owner_reputation,
    badge_count,
    total_bounty_amount,
    upvote_count,
    downvote_count,
    total_comment_score
FROM tag_post_metrics
ORDER BY post_count DESC
LIMIT 20
