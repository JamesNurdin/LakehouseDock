WITH user_base AS (
    SELECT id AS user_id,
           reputation
    FROM users
),

user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS total_posts,
           COALESCE(SUM(score), 0) AS total_post_score,
           COALESCE(SUM(viewcount), 0) AS total_viewcount,
           COALESCE(SUM(answercount), 0) AS total_answercount,
           COALESCE(SUM(commentcount), 0) AS total_commentcount_on_posts
    FROM posts
    GROUP BY owneruserid
),

user_comments AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_comments,
           COALESCE(SUM(score), 0) AS total_comment_score
    FROM comments
    GROUP BY userid
),

user_votes_cast AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_votes_cast
    FROM votes
    GROUP BY userid
),

user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS total_votes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS up_votes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS down_votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),

user_badges AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_badges
    FROM badges
    GROUP BY userid
),

user_postlinks AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS total_post_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),

user_tags AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS total_tag_excerpts
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),

user_posthistory AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_post_history
    FROM posthistory
    GROUP BY userid
)

SELECT u.user_id,
       u.reputation,
       COALESCE(p.total_posts, 0) AS total_posts,
       COALESCE(p.total_post_score, 0) AS total_post_score,
       COALESCE(c.total_comments, 0) AS total_comments,
       COALESCE(c.total_comment_score, 0) AS total_comment_score,
       COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
       COALESCE(vr.total_votes_received, 0) AS total_votes_received,
       COALESCE(b.total_badges, 0) AS total_badges,
       COALESCE(pl.total_post_links, 0) AS total_post_links,
       COALESCE(t.total_tag_excerpts, 0) AS total_tag_excerpts,
       COALESCE(ph.total_post_history, 0) AS total_post_history
FROM user_base u
LEFT JOIN user_posts p            ON u.user_id = p.user_id
LEFT JOIN user_comments c         ON u.user_id = c.user_id
LEFT JOIN user_votes_cast vc      ON u.user_id = vc.user_id
LEFT JOIN user_votes_received vr  ON u.user_id = vr.user_id
LEFT JOIN user_badges b           ON u.user_id = b.user_id
LEFT JOIN user_postlinks pl       ON u.user_id = pl.user_id
LEFT JOIN user_tags t             ON u.user_id = t.user_id
LEFT JOIN user_posthistory ph     ON u.user_id = ph.user_id
ORDER BY total_posts DESC, u.reputation DESC
LIMIT 100
