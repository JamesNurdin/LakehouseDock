WITH
    -- Posts owned by each user
    user_posts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS post_count,
            COALESCE(SUM(p.score), 0) AS post_score_sum,
            COALESCE(AVG(p.score), 0) AS post_score_avg,
            COALESCE(SUM(p.viewcount), 0) AS post_view_sum
        FROM posts p
        GROUP BY p.owneruserid
    ),
    -- Comments written by each user
    user_comments AS (
        SELECT
            c.userid,
            COUNT(*) AS comment_count,
            COALESCE(SUM(c.score), 0) AS comment_score_sum
        FROM comments c
        GROUP BY c.userid
    ),
    -- Votes cast by each user (including bounty amount)
    user_votes AS (
        SELECT
            v.userid,
            COUNT(*) AS vote_count,
            COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cast,
            COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cast,
            COALESCE(SUM(v.bountyamount), 0) AS total_bounty_given
        FROM votes v
        GROUP BY v.userid
    ),
    -- Badges earned by each user
    user_badges AS (
        SELECT
            b.userid,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    -- Tag excerpts that belong to posts owned by each user
    user_tag_counts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(t.id) AS tag_excerpt_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.upvotes AS total_upvotes_received,
    u.downvotes AS total_downvotes_received,
    u.views AS total_views_received,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.post_score_sum, 0) AS post_score_sum,
    COALESCE(p.post_score_avg, 0) AS post_score_avg,
    COALESCE(p.post_view_sum, 0) AS post_view_sum,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(v.vote_count, 0) AS vote_cast_count,
    COALESCE(v.upvote_cast, 0) AS upvote_cast,
    COALESCE(v.downvote_cast, 0) AS downvote_cast,
    COALESCE(v.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(t.tag_excerpt_count, 0) AS tag_excerpt_count
FROM users u
LEFT JOIN user_posts p ON p.userid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
LEFT JOIN user_votes v ON v.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_tag_counts t ON t.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
