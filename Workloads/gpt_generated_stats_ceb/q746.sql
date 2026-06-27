WITH tag_metrics AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.score), 0) AS avg_post_score,
        COUNT(DISTINCT v.id) AS vote_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT pl.id) AS postlink_count,
        COUNT(DISTINCT ph.id) AS posthistory_count,
        COUNT(DISTINCT p.owneruserid) AS distinct_owner_user_count,
        COUNT(DISTINCT b.id) AS badge_count_for_owners
    FROM tags t
    LEFT JOIN posts p
        ON p.id = t.excerptpostid
    LEFT JOIN votes v
        ON v.postid = p.id
    LEFT JOIN comments c
        ON c.postid = p.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    LEFT JOIN users u
        ON u.id = p.owneruserid
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY t.id
)
SELECT
    tag_id,
    post_count,
    total_post_score,
    avg_post_score,
    vote_count,
    total_bounty_amount,
    comment_count,
    postlink_count,
    posthistory_count,
    distinct_owner_user_count,
    badge_count_for_owners
FROM tag_metrics
ORDER BY total_post_score DESC
LIMIT 10
