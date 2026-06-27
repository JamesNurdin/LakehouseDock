WITH user_posts AS (
    SELECT
        owneruserid,
        count(*) AS post_count,
        sum(score) AS post_score_sum,
        sum(viewcount) AS post_view_sum
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        count(*) AS comment_count,
        sum(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid,
        count(*) AS vote_count,
        sum(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        sum(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid,
        count(*) AS badge_count
    FROM badges
    GROUP BY userid
)
SELECT
    u.id,
    u.reputation,
    coalesce(p.post_count, 0) AS post_count,
    coalesce(p.post_score_sum, 0) AS post_score_sum,
    coalesce(p.post_view_sum, 0) AS post_view_sum,
    coalesce(c.comment_count, 0) AS comment_count,
    coalesce(c.comment_score_sum, 0) AS comment_score_sum,
    coalesce(v.vote_count, 0) AS vote_count,
    coalesce(v.upvote_count, 0) AS upvote_count,
    coalesce(v.downvote_count, 0) AS downvote_count,
    coalesce(b.badge_count, 0) AS badge_count,
    (coalesce(p.post_view_sum, 0) / nullif(coalesce(p.post_count, 0), 0)) AS avg_views_per_post
FROM users u
LEFT JOIN user_posts p ON p.owneruserid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
LEFT JOIN user_votes v ON v.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
ORDER BY (
    coalesce(p.post_count, 0) +
    coalesce(c.comment_count, 0) +
    coalesce(v.vote_count, 0) +
    coalesce(b.badge_count, 0)
) DESC
LIMIT 100
