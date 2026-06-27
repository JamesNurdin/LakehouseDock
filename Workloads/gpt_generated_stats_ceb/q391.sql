WITH user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS total_posts,
           SUM(CASE WHEN posttypeid = 1 THEN 1 ELSE 0 END) AS total_questions,
           SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers,
           SUM(score) AS total_post_score,
           SUM(viewcount) AS total_post_views,
           SUM(favoritecount) AS total_favoritecount
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_comments_written,
           SUM(score) AS total_comment_score_written
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_votes_cast,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS total_upvotes_cast,
           SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS total_downvotes_cast,
           SUM(bountyamount) AS total_bounty_given
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS total_votes_received,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS total_upvotes_received,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS total_downvotes_received,
           SUM(v.bountyamount) AS total_bounty_received
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
user_posthistory AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_post_edits
    FROM posthistory
    GROUP BY userid
),
user_postlinks AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS total_postlinks_created
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tag_excerpts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS total_tag_excerpts
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.total_posts, 0) AS total_posts,
       COALESCE(up.total_questions, 0) AS total_questions,
       COALESCE(up.total_answers, 0) AS total_answers,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_post_views, 0) AS total_post_views,
       COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
       COALESCE(uc.total_comments_written, 0) AS total_comments_written,
       COALESCE(uc.total_comment_score_written, 0) AS total_comment_score_written,
       COALESCE(uvc.total_votes_cast, 0) AS total_votes_cast,
       COALESCE(uvc.total_upvotes_cast, 0) AS total_upvotes_cast,
       COALESCE(uvc.total_downvotes_cast, 0) AS total_downvotes_cast,
       COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
       COALESCE(uvr.total_votes_received, 0) AS total_votes_received,
       COALESCE(uvr.total_upvotes_received, 0) AS total_upvotes_received,
       COALESCE(uvr.total_downvotes_received, 0) AS total_downvotes_received,
       COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
       COALESCE(ub.total_badges, 0) AS total_badges,
       COALESCE(uph.total_post_edits, 0) AS total_post_edits,
       COALESCE(ul.total_postlinks_created, 0) AS total_postlinks_created,
       COALESCE(ut.total_tag_excerpts, 0) AS total_tag_excerpts,
       CASE WHEN COALESCE(up.total_posts, 0) > 0 THEN COALESCE(up.total_post_score, 0) / NULLIF(up.total_posts, 0) END AS avg_post_score,
       CASE WHEN COALESCE(uc.total_comments_written, 0) > 0 THEN COALESCE(uc.total_comment_score_written, 0) / NULLIF(uc.total_comments_written, 0) END AS avg_comment_score,
       CASE WHEN COALESCE(up.total_posts, 0) > 0 THEN COALESCE(uvr.total_votes_received, 0) / NULLIF(up.total_posts, 0) END AS avg_votes_received_per_post,
       CASE WHEN COALESCE(up.total_posts, 0) > 0 THEN COALESCE(ub.total_badges, 0) / NULLIF(up.total_posts, 0) END AS badge_to_post_ratio
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_postlinks ul ON ul.user_id = u.id
LEFT JOIN user_tag_excerpts ut ON ut.user_id = u.id
ORDER BY total_posts DESC
LIMIT 100
