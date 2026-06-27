WITH posts_agg AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS post_count,
           SUM(p.score) AS total_post_score,
           SUM(p.viewcount) AS total_views,
           SUM(p.favoritecount) AS total_favorites,
           SUM(p.answercount) AS total_answers,
           SUM(p.commentcount) AS total_comments_on_posts
    FROM posts p
    GROUP BY p.owneruserid
),
comments_agg AS (
    SELECT p.owneruserid AS user_id,
           COUNT(c.id) AS comment_count_on_posts
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
votes_agg AS (
    SELECT p.owneruserid AS user_id,
           COUNT(v.id) AS vote_count,
           SUM(v.bountyamount) AS total_bounty
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
badges_agg AS (
    SELECT b.userid AS user_id,
           COUNT(b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(pag.post_count, 0) AS post_count,
       COALESCE(pag.total_post_score, 0) AS total_post_score,
       CASE WHEN COALESCE(pag.post_count, 0) = 0 THEN 0
            ELSE COALESCE(pag.total_post_score, 0) / COALESCE(pag.post_count, 0)
       END AS avg_post_score,
       COALESCE(pag.total_views, 0) AS total_views,
       COALESCE(comag.comment_count_on_posts, 0) AS comment_count_on_posts,
       COALESCE(vag.vote_count, 0) AS vote_count,
       COALESCE(vag.total_bounty, 0) AS total_bounty,
       COALESCE(bag.badge_count, 0) AS badge_count
FROM users u
LEFT JOIN posts_agg pag   ON u.id = pag.user_id
LEFT JOIN comments_agg comag ON u.id = comag.user_id
LEFT JOIN votes_agg vag   ON u.id = vag.user_id
LEFT JOIN badges_agg bag  ON u.id = bag.user_id
WHERE u.reputation > 1000
ORDER BY avg_post_score DESC
LIMIT 20
