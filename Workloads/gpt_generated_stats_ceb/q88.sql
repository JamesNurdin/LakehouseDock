WITH user_base AS (
    SELECT id,
           reputation,
           creationdate,
           views,
           upvotes,
           downvotes
    FROM users
),
post_metrics AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS total_posts,
           SUM(score) AS total_post_score,
           SUM(viewcount) AS total_post_views,
           SUM(favoritecount) AS total_favorite_count,
           SUM(answercount) AS total_answer_count,
           SUM(commentcount) AS total_comment_count
    FROM posts
    GROUP BY owneruserid
),
comment_metrics AS (
    SELECT userid,
           COUNT(*) AS total_comments_made,
           SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
vote_cast_metrics AS (
    SELECT userid,
           COUNT(*) AS total_votes_cast,
           SUM(COALESCE(bountyamount, 0)) AS total_vote_bounty
    FROM votes
    GROUP BY userid
),
vote_received_metrics AS (
    SELECT p.owneruserid AS userid,
           COUNT(v.id) AS total_votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
badge_metrics AS (
    SELECT userid,
           COUNT(*) AS total_badges
    FROM badges
    GROUP BY userid
),
tag_metrics AS (
    SELECT p.owneruserid AS userid,
           COUNT(t.id) AS total_tags_used
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
posthistory_metrics AS (
    SELECT userid,
           COUNT(*) AS total_post_edits
    FROM posthistory
    GROUP BY userid
),
postlink_metrics AS (
    SELECT p.owneruserid AS userid,
           COUNT(pl.id) AS total_post_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(pm.total_posts, 0)          AS total_posts,
       COALESCE(pm.total_post_score, 0)    AS total_post_score,
       COALESCE(pm.total_post_views, 0)    AS total_post_views,
       COALESCE(pm.total_favorite_count, 0) AS total_favorite_count,
       COALESCE(pm.total_answer_count, 0) AS total_answer_count,
       COALESCE(pm.total_comment_count, 0) AS total_comment_count,
       COALESCE(cm.total_comments_made, 0) AS total_comments_made,
       COALESCE(cm.total_comment_score, 0) AS total_comment_score,
       COALESCE(vc.total_votes_cast, 0)    AS total_votes_cast,
       COALESCE(vc.total_vote_bounty, 0)   AS total_vote_bounty,
       COALESCE(vr.total_votes_received, 0) AS total_votes_received,
       COALESCE(bm.total_badges, 0)        AS total_badges,
       COALESCE(tm.total_tags_used, 0)     AS total_tags_used,
       COALESCE(phm.total_post_edits, 0)   AS total_post_edits,
       COALESCE(plm.total_post_links, 0)   AS total_post_links
FROM user_base u
LEFT JOIN post_metrics pm          ON pm.userid = u.id
LEFT JOIN comment_metrics cm       ON cm.userid = u.id
LEFT JOIN vote_cast_metrics vc    ON vc.userid = u.id
LEFT JOIN vote_received_metrics vr ON vr.userid = u.id
LEFT JOIN badge_metrics bm        ON bm.userid = u.id
LEFT JOIN tag_metrics tm          ON tm.userid = u.id
LEFT JOIN posthistory_metrics phm ON phm.userid = u.id
LEFT JOIN postlink_metrics plm    ON plm.userid = u.id
ORDER BY total_posts DESC, u.id
LIMIT 100
