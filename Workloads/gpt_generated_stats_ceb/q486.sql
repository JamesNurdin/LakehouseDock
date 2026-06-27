WITH user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           COUNT(CASE WHEN posttypeid = 2 THEN 1 END) AS answer_count,
           AVG(score) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid,
           COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p
      ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_tag_excerpts AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS tag_excerpts
    FROM tags t
    JOIN posts p
      ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_edits AS (
    SELECT userid,
           COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),
user_post_links AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS post_links
    FROM postlinks pl
    JOIN posts p
      ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_related_links AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS related_links
    FROM postlinks pl
    JOIN posts p
      ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id,
       u.reputation,
       COALESCE(b.badge_count, 0)          AS badge_count,
       COALESCE(p.post_count, 0)           AS post_count,
       COALESCE(p.answer_count, 0)         AS answer_count,
       COALESCE(p.avg_post_score, 0)       AS avg_post_score,
       COALESCE(c.comment_count, 0)        AS comment_count,
       COALESCE(vc.votes_cast, 0)          AS votes_cast,
       COALESCE(vr.votes_received, 0)      AS votes_received,
       COALESCE(t.tag_excerpts, 0)         AS tag_excerpts,
       COALESCE(e.edit_count, 0)           AS edit_count,
       COALESCE(pl.post_links, 0)          AS post_links,
       COALESCE(rl.related_links, 0)       AS related_links
FROM users u
LEFT JOIN user_badges b          ON b.userid = u.id
LEFT JOIN user_posts p           ON p.userid = u.id
LEFT JOIN user_comments c        ON c.userid = u.id
LEFT JOIN user_votes_cast vc    ON vc.userid = u.id
LEFT JOIN user_votes_received vr ON vr.userid = u.id
LEFT JOIN user_tag_excerpts t    ON t.userid = u.id
LEFT JOIN user_edits e           ON e.userid = u.id
LEFT JOIN user_post_links pl     ON pl.userid = u.id
LEFT JOIN user_related_links rl  ON rl.userid = u.id
ORDER BY u.reputation DESC
LIMIT 20
