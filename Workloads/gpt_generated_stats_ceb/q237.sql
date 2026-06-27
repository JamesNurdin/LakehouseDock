WITH user_badges AS (
    SELECT users.id AS user_id,
           COUNT(badges.id) AS badge_count
    FROM users
    LEFT JOIN badges ON badges.userid = users.id
    GROUP BY users.id
),
user_posts AS (
    SELECT users.id AS user_id,
           COUNT(posts.id) AS post_count,
           COALESCE(SUM(posts.score), 0) AS post_score_sum
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    GROUP BY users.id
),
user_comments AS (
    SELECT users.id AS user_id,
           COUNT(comments.id) AS comment_count,
           COALESCE(AVG(comments.score), 0) AS avg_comment_score
    FROM users
    LEFT JOIN comments ON comments.userid = users.id
    GROUP BY users.id
),
user_votes_cast AS (
    SELECT users.id AS user_id,
           COUNT(votes.id) AS votes_cast_count
    FROM users
    LEFT JOIN votes ON votes.userid = users.id
    GROUP BY users.id
),
user_votes_received AS (
    SELECT users.id AS user_id,
           COUNT(votes.id) AS votes_received_count
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    LEFT JOIN votes ON votes.postid = posts.id
    GROUP BY users.id
),
user_links_source AS (
    SELECT users.id AS user_id,
           COUNT(postlinks.id) AS source_link_count
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    LEFT JOIN postlinks ON postlinks.postid = posts.id
    GROUP BY users.id
),
user_links_target AS (
    SELECT users.id AS user_id,
           COUNT(postlinks.id) AS target_link_count
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    LEFT JOIN postlinks ON postlinks.relatedpostid = posts.id
    GROUP BY users.id
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(b.badge_count, 0) AS badge_count,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.post_score_sum, 0) AS post_score_sum,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
       COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
       COALESCE(vr.votes_received_count, 0) AS votes_received_count,
       COALESCE(ls.source_link_count, 0) + COALESCE(lt.target_link_count, 0) AS postlink_total_count
FROM users u
LEFT JOIN user_badges b          ON b.user_id = u.id
LEFT JOIN user_posts p           ON p.user_id = u.id
LEFT JOIN user_comments c        ON c.user_id = u.id
LEFT JOIN user_votes_cast vc    ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_links_source ls   ON ls.user_id = u.id
LEFT JOIN user_links_target lt   ON lt.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
