WITH user_posts AS (
    SELECT o.owneruserid AS userid,
           COUNT(*) AS posts_owned,
           COALESCE(SUM(o.score), 0) AS posts_owned_score
    FROM posts o
    GROUP BY o.owneruserid
),
user_edits AS (
    SELECT e.lasteditoruserid AS userid,
           COUNT(*) AS posts_edited,
           COALESCE(SUM(e.score), 0) AS posts_edited_score
    FROM posts e
    GROUP BY e.lasteditoruserid
),
user_comments AS (
    SELECT c.userid,
           COUNT(*) AS comments_count,
           COALESCE(SUM(c.score), 0) AS comments_score_sum
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT v.userid,
           COUNT(*) AS votes_cast,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT b.userid,
           COUNT(*) AS badges_count
    FROM badges b
    GROUP BY b.userid
),
user_history AS (
    SELECT h.userid,
           COUNT(*) AS history_count
    FROM posthistory h
    GROUP BY h.userid
),
user_links AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS links_created
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS tags_owned
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(p.posts_owned, 0) AS posts_owned,
       COALESCE(p.posts_owned_score, 0) AS posts_owned_score,
       COALESCE(e.posts_edited, 0) AS posts_edited,
       COALESCE(e.posts_edited_score, 0) AS posts_edited_score,
       COALESCE(c.comments_count, 0) AS comments_count,
       COALESCE(c.comments_score_sum, 0) AS comments_score_sum,
       COALESCE(v.votes_cast, 0) AS votes_cast,
       COALESCE(v.upvote_count, 0) AS upvote_count,
       COALESCE(v.downvote_count, 0) AS downvote_count,
       COALESCE(b.badges_count, 0) AS badges_count,
       COALESCE(h.history_count, 0) AS history_count,
       COALESCE(l.links_created, 0) AS links_created,
       COALESCE(t.tags_owned, 0) AS tags_owned
FROM users u
LEFT JOIN user_posts p ON p.userid = u.id
LEFT JOIN user_edits e ON e.userid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
LEFT JOIN user_votes v ON v.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_history h ON h.userid = u.id
LEFT JOIN user_links l ON l.userid = u.id
LEFT JOIN user_tags t ON t.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
