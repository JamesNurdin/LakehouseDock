WITH post_agg AS (
    SELECT owneruserid,
           COUNT(*) AS post_count,
           SUM(score) AS post_score_sum,
           SUM(viewcount) AS post_view_sum
    FROM posts
    GROUP BY owneruserid
),
comment_agg AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
vote_agg AS (
    SELECT userid,
           COUNT(*) AS vote_count,
           COUNT(CASE WHEN votetypeid = 1 THEN 1 END) AS upvote_count,
           COUNT(CASE WHEN votetypeid = 2 THEN 1 END) AS downvote_count
    FROM votes
    GROUP BY userid
),
badge_agg AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
tag_agg AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.post_score_sum, 0) AS post_score_sum,
       COALESCE(p.post_view_sum, 0) AS post_view_sum,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(v.vote_count, 0) AS vote_count,
       COALESCE(v.upvote_count, 0) AS upvote_count,
       COALESCE(v.downvote_count, 0) AS downvote_count,
       COALESCE(b.badge_count, 0) AS badge_count,
       COALESCE(tg.tag_count, 0) AS tag_count,
       (COALESCE(p.post_count, 0) * 5
        + COALESCE(c.comment_count, 0) * 1
        + COALESCE(v.vote_count, 0) * 0.5
        + COALESCE(b.badge_count, 0) * 3
        + COALESCE(tg.tag_count, 0) * 4
        + COALESCE(u.reputation, 0) / 1000) AS activity_score
FROM users u
LEFT JOIN post_agg p ON p.owneruserid = u.id
LEFT JOIN comment_agg c ON c.userid = u.id
LEFT JOIN vote_agg v ON v.userid = u.id
LEFT JOIN badge_agg b ON b.userid = u.id
LEFT JOIN tag_agg tg ON tg.userid = u.id
ORDER BY activity_score DESC
LIMIT 20
