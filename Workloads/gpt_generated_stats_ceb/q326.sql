WITH post_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.score), 0) AS avg_post_score
    FROM posts p
    GROUP BY p.owneruserid
),
comment_stats AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
vote_stats AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_given_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_given,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_given
    FROM votes v
    GROUP BY v.userid
),
badge_stats AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
posthistory_stats AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS post_edits,
        COUNT(DISTINCT ph.postid) AS distinct_posts_edited
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_score, 0) AS total_post_score,
    COALESCE(ps.avg_post_score, 0) AS avg_post_score,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_score, 0) AS total_comment_score,
    COALESCE(vs.vote_given_count, 0) AS vote_given_count,
    COALESCE(vs.upvotes_given, 0) AS upvotes_given,
    COALESCE(vs.downvotes_given, 0) AS downvotes_given,
    COALESCE(bs.badge_count, 0) AS badge_count,
    COALESCE(phs.post_edits, 0) AS post_edits,
    COALESCE(phs.distinct_posts_edited, 0) AS distinct_posts_edited
FROM users u
LEFT JOIN post_stats ps ON ps.user_id = u.id
LEFT JOIN comment_stats cs ON cs.user_id = u.id
LEFT JOIN vote_stats vs ON vs.user_id = u.id
LEFT JOIN badge_stats bs ON bs.user_id = u.id
LEFT JOIN posthistory_stats phs ON phs.user_id = u.id
ORDER BY u.reputation DESC, post_count DESC
LIMIT 200
