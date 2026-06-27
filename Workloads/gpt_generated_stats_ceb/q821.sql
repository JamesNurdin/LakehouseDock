WITH vote_counts AS (
    SELECT
        v.postid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes v
    GROUP BY v.postid
),
badge_counts AS (
    SELECT
        b.userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_agg AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(DISTINCT p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(vc.vote_count), 0) AS total_votes_received,
        COALESCE(SUM(vc.upvote_count), 0) AS total_upvotes_received,
        COALESCE(SUM(vc.downvote_count), 0) AS total_downvotes_received,
        COALESCE(bc.badge_count, 0) AS badge_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN vote_counts vc ON vc.postid = p.id
    LEFT JOIN badge_counts bc ON bc.userid = u.id
    GROUP BY u.id, u.reputation, bc.badge_count
)
SELECT
    user_id,
    reputation,
    post_count,
    total_post_score,
    total_votes_received,
    total_upvotes_received,
    total_downvotes_received,
    badge_count,
    ROW_NUMBER() OVER (ORDER BY reputation DESC) AS reputation_rank
FROM user_agg
ORDER BY reputation DESC
LIMIT 10
