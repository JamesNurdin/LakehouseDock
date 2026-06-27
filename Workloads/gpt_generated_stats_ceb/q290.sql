WITH post_stats AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_views
    FROM posts
    GROUP BY owneruserid
),
vote_stats AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(v.id) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_stats AS (
    SELECT
        COALESCE(ps.userid, vs.userid) AS userid,
        COALESCE(ps.post_count, 0) AS post_count,
        COALESCE(ps.avg_post_score, 0) AS avg_post_score,
        COALESCE(ps.total_views, 0) AS total_views,
        COALESCE(vs.vote_count, 0) AS vote_count,
        COALESCE(vs.upvote_count, 0) AS upvote_count,
        COALESCE(vs.downvote_count, 0) AS downvote_count
    FROM post_stats ps
    FULL OUTER JOIN vote_stats vs ON ps.userid = vs.userid
),
badge_monthly AS (
    SELECT
        date_trunc('month', b.date) AS badge_month,
        COUNT(b.id) AS total_badges,
        COUNT(DISTINCT b.userid) AS distinct_users,
        AVG(u.reputation) AS avg_user_reputation,
        SUM(us.post_count) AS total_posts_by_badge_earners,
        AVG(us.avg_post_score) AS avg_post_score_of_earners,
        SUM(us.total_views) AS total_views_of_earners,
        SUM(us.vote_count) AS total_votes_on_earners_posts,
        SUM(us.upvote_count) AS total_upvotes_on_earners_posts,
        SUM(us.downvote_count) AS total_downvotes_on_earners_posts
    FROM badges b
    JOIN users u ON b.userid = u.id
    LEFT JOIN user_stats us ON us.userid = u.id
    GROUP BY date_trunc('month', b.date)
)
SELECT
    badge_month,
    total_badges,
    distinct_users,
    avg_user_reputation,
    total_posts_by_badge_earners,
    avg_post_score_of_earners,
    total_views_of_earners,
    total_votes_on_earners_posts,
    total_upvotes_on_earners_posts,
    total_downvotes_on_earners_posts,
    SUM(total_badges) OVER (ORDER BY badge_month) AS cumulative_badges
FROM badge_monthly
ORDER BY badge_month
