WITH post_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS post_score_sum,
        AVG(p.score) AS post_score_avg
    FROM posts p
    GROUP BY p.owneruserid
),
comment_stats AS (
    SELECT
        c.userid AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS comment_score_sum,
        AVG(c.score) AS comment_score_avg
    FROM comments c
    GROUP BY c.userid
),
badge_stats AS (
    SELECT
        b.userid AS user_id,
        COUNT(b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
vote_cast_stats AS (
    SELECT
        v.userid AS user_id,
        COUNT(v.id) AS votes_cast_count,
        SUM(v.bountyamount) AS bounty_cast_sum
    FROM votes v
    GROUP BY v.userid
),
vote_received_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received_count,
        SUM(v.bountyamount) AS bounty_received_sum
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
tag_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_used_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
posthistory_stats AS (
    SELECT
        ph.userid AS user_id,
        COUNT(ph.id) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.post_score_sum, 0) AS post_score_sum,
    COALESCE(ps.post_score_avg, 0) AS post_score_avg,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(cs.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(bs.badge_count, 0) AS badge_count,
    COALESCE(vcs.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vcs.bounty_cast_sum, 0) AS bounty_cast_sum,
    COALESCE(vrs.votes_received_count, 0) AS votes_received_count,
    COALESCE(vrs.bounty_received_sum, 0) AS bounty_received_sum,
    COALESCE(ts.tag_used_count, 0) AS tag_used_count,
    COALESCE(phs.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN post_stats ps ON ps.user_id = u.id
LEFT JOIN comment_stats cs ON cs.user_id = u.id
LEFT JOIN badge_stats bs ON bs.user_id = u.id
LEFT JOIN vote_cast_stats vcs ON vcs.user_id = u.id
LEFT JOIN vote_received_stats vrs ON vrs.user_id = u.id
LEFT JOIN tag_stats ts ON ts.user_id = u.id
LEFT JOIN posthistory_stats phs ON phs.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
