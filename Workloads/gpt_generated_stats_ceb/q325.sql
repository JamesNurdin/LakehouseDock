WITH user_info AS (
    SELECT id,
           reputation,
           creationdate
    FROM users
),
post_counts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS total_posts,
           SUM(CASE WHEN posttypeid = 1 THEN 1 ELSE 0 END) AS total_questions,
           SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers,
           COALESCE(SUM(score), 0) AS total_post_score,
           COALESCE(SUM(viewcount), 0) AS total_viewcount,
           COALESCE(SUM(favoritecount), 0) AS total_favoritecount
    FROM posts
    GROUP BY owneruserid
),
comment_counts AS (
    SELECT userid,
           COUNT(*) AS total_comments_made
    FROM comments
    GROUP BY userid
),
comments_received AS (
    SELECT p.owneruserid AS userid,
           COUNT(c.id) AS total_comments_received
    FROM posts p
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY p.owneruserid
),
vote_counts AS (
    SELECT userid,
           COUNT(*) AS total_votes_given
    FROM votes
    GROUP BY userid
),
votes_received AS (
    SELECT p.owneruserid AS userid,
           COUNT(v.id) AS total_votes_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
badge_counts AS (
    SELECT userid,
           COUNT(*) AS total_badges
    FROM badges
    GROUP BY userid
),
edit_counts AS (
    SELECT userid,
           COUNT(*) AS total_edits
    FROM posthistory
    GROUP BY userid
),
tag_excerpts AS (
    SELECT p.owneruserid AS userid,
           COUNT(t.id) AS total_tag_excerpts
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id,
       u.reputation,
       u.creationdate,
       COALESCE(pc.total_posts, 0)          AS total_posts,
       COALESCE(pc.total_questions, 0)     AS total_questions,
       COALESCE(pc.total_answers, 0)       AS total_answers,
       COALESCE(pc.total_post_score, 0)    AS total_post_score,
       COALESCE(cc.total_comments_made, 0) AS total_comments_made,
       COALESCE(cr.total_comments_received, 0) AS total_comments_received,
       COALESCE(vc.total_votes_given, 0)   AS total_votes_given,
       COALESCE(vr.total_votes_received, 0) AS total_votes_received,
       COALESCE(bc.total_badges, 0)        AS total_badges,
       COALESCE(ec.total_edits, 0)         AS total_edits,
       COALESCE(te.total_tag_excerpts, 0)  AS total_tag_excerpts
FROM user_info u
LEFT JOIN post_counts pc          ON pc.userid = u.id
LEFT JOIN comment_counts cc       ON cc.userid = u.id
LEFT JOIN comments_received cr    ON cr.userid = u.id
LEFT JOIN vote_counts vc          ON vc.userid = u.id
LEFT JOIN votes_received vr       ON vr.userid = u.id
LEFT JOIN badge_counts bc         ON bc.userid = u.id
LEFT JOIN edit_counts ec          ON ec.userid = u.id
LEFT JOIN tag_excerpts te         ON te.userid = u.id
ORDER BY total_posts DESC
LIMIT 100
