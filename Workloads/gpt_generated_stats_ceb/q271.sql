WITH user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           AVG(score) AS avg_post_score,
           SUM(viewcount) AS total_viewcount
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid AS user_id,
           COUNT(*) AS comment_count,
           SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_comments_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS comment_received_count
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_given AS (
    SELECT userid AS user_id,
           COUNT(*) AS votes_given,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_given,
           SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_given
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS votes_received,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_received,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_tags AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_posthistory AS (
    SELECT userid AS user_id,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_posthistory_by_type AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS posthistory_by_type_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
user_outgoing_links AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS outgoing_link_count,
           COUNT(DISTINCT pl.relatedpostid) AS distinct_outgoing_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_incoming_links AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS incoming_link_count,
           COUNT(DISTINCT pl.postid) AS distinct_incoming_links
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.avg_post_score, 0) AS avg_post_score,
       COALESCE(up.total_viewcount, 0) AS total_viewcount,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(ucr.comment_received_count, 0) AS comment_received_count,
       COALESCE(ugv.votes_given, 0) AS votes_given,
       COALESCE(ugv.upvote_given, 0) AS upvote_given,
       COALESCE(ugv.downvote_given, 0) AS downvote_given,
       COALESCE(urv.votes_received, 0) AS votes_received,
       COALESCE(urv.upvote_received, 0) AS upvote_received,
       COALESCE(urv.downvote_received, 0) AS downvote_received,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count,
       COALESCE(uptb.posthistory_by_type_count, 0) AS posthistory_by_type_count,
       COALESCE(uol.outgoing_link_count, 0) AS outgoing_link_count,
       COALESCE(uol.distinct_outgoing_links, 0) AS distinct_outgoing_links,
       COALESCE(uil.incoming_link_count, 0) AS incoming_link_count,
       COALESCE(uil.distinct_incoming_links, 0) AS distinct_incoming_links
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_comments_received ucr ON ucr.user_id = u.id
LEFT JOIN user_votes_given ugv ON ugv.user_id = u.id
LEFT JOIN user_votes_received urv ON urv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_posthistory_by_type uptb ON uptb.user_id = u.id
LEFT JOIN user_outgoing_links uol ON uol.user_id = u.id
LEFT JOIN user_incoming_links uil ON uil.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
