WITH post_votes AS (
    SELECT p.id AS post_id,
           p.owneruserid AS owner_user_id,
           COUNT(v.id) AS votes_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.id, p.owneruserid
),
post_agg AS (
    SELECT p.owneruserid AS user_id,
           COUNT(p.id) AS posts_owned,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(SUM(p.answercount), 0) AS total_answers,
           COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts,
           COALESCE(SUM(pv.votes_received), 0) AS total_votes_received
    FROM posts p
    LEFT JOIN post_votes pv ON pv.post_id = p.id
    GROUP BY p.owneruserid
),
comment_agg AS (
    SELECT c.userid AS user_id,
           COUNT(c.id) AS comments_made,
           COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
vote_cast_agg AS (
    SELECT v.userid AS user_id,
           COUNT(v.id) AS votes_cast
    FROM votes v
    GROUP BY v.userid
),
postlink_as_post AS (
    SELECT p.owneruserid AS user_id,
           COUNT(pl.id) AS postlinks_as_post
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
postlink_as_related AS (
    SELECT p.owneruserid AS user_id,
           COUNT(pl.id) AS postlinks_as_related
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(pa.posts_owned, 0) AS posts_owned,
       COALESCE(pa.total_votes_received, 0) AS total_votes_received,
       COALESCE(pa.total_post_score, 0) AS total_post_score,
       COALESCE(pa.total_answers, 0) AS total_answers,
       COALESCE(pa.total_comments_on_posts, 0) AS total_comments_on_posts,
       COALESCE(ca.total_comment_score, 0) AS total_comment_score,
       COALESCE(ca.comments_made, 0) AS comments_made,
       COALESCE(vca.votes_cast, 0) AS votes_cast,
       COALESCE(plp.postlinks_as_post, 0) + COALESCE(plr.postlinks_as_related, 0) AS total_postlinks,
       (COALESCE(pa.total_post_score, 0) + COALESCE(ca.total_comment_score, 0)) AS total_score_contribution
FROM users u
LEFT JOIN post_agg pa ON pa.user_id = u.id
LEFT JOIN comment_agg ca ON ca.user_id = u.id
LEFT JOIN vote_cast_agg vca ON vca.user_id = u.id
LEFT JOIN postlink_as_post plp ON plp.user_id = u.id
LEFT JOIN postlink_as_related plr ON plr.user_id = u.id
ORDER BY total_score_contribution DESC
LIMIT 20
