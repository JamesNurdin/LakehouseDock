WITH post_stats AS (
    SELECT
        u.id,
        COUNT(p.id) AS authored_posts,
        SUM(p.score) AS authored_score_sum,
        AVG(p.score) AS authored_score_avg,
        SUM(p.viewcount) AS authored_views,
        SUM(p.favoritecount) AS authored_favorites
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
edit_stats AS (
    SELECT
        u.id,
        COUNT(p.id) AS edited_posts,
        SUM(p.score) AS edited_score_sum,
        AVG(p.score) AS edited_score_avg
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
vote_stats AS (
    SELECT
        u.id,
        COUNT(v.id) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast,
        COUNT(DISTINCT v.postid) AS distinct_posts_voted
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
badge_stats AS (
    SELECT
        u.id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    COALESCE(ps.authored_posts, 0) AS authored_posts,
    COALESCE(ps.authored_score_sum, 0) AS authored_score_sum,
    COALESCE(ps.authored_score_avg, 0) AS authored_score_avg,
    COALESCE(es.edited_posts, 0) AS edited_posts,
    COALESCE(vs.votes_cast, 0) AS votes_cast,
    COALESCE(vs.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vs.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vs.distinct_posts_voted, 0) AS distinct_posts_voted,
    COALESCE(bs.badge_count, 0) AS badge_count,
    CASE 
        WHEN COALESCE(vs.downvotes_cast, 0) = 0 THEN COALESCE(vs.upvotes_cast, 0)
        ELSE COALESCE(vs.upvotes_cast, 0) * 1.0 / vs.downvotes_cast
    END AS upvote_to_downvote_ratio
FROM users u
LEFT JOIN post_stats ps ON ps.id = u.id
LEFT JOIN edit_stats es ON es.id = u.id
LEFT JOIN vote_stats vs ON vs.id = u.id
LEFT JOIN badge_stats bs ON bs.id = u.id
WHERE u.reputation > 1000
ORDER BY u.reputation DESC
LIMIT 50
