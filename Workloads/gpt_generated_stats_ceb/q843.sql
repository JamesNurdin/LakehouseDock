WITH user_base AS (
    SELECT id, reputation
    FROM users
),
posts_agg AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS total_posts,
           COALESCE(SUM(score), 0) AS total_post_score,
           CASE WHEN COUNT(*) = 0 THEN 0 ELSE AVG(score) END AS avg_post_score
    FROM posts
    GROUP BY owneruserid
),
comments_on_posts_agg AS (
    SELECT p.owneruserid AS user_id,
           COUNT(c.id) AS total_comments_received,
           COALESCE(SUM(c.score), 0) AS total_comment_score_received
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
comments_made_agg AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_comments_made
    FROM comments
    GROUP BY userid
),
votes_cast_agg AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_votes_cast,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS total_upvotes_given,
           COALESCE(SUM(bountyamount), 0) AS total_bounty_given
    FROM votes
    GROUP BY userid
),
badges_agg AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_badges
    FROM badges
    GROUP BY userid
),
posthistory_agg AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_edits
    FROM posthistory
    GROUP BY userid
),
tags_agg AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS total_tags_in_owned_posts
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
postlinks_outgoing_agg AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS total_outgoing_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
postlinks_incoming_agg AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS total_incoming_links
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id,
       u.reputation,
       COALESCE(p.total_posts, 0) AS total_posts,
       COALESCE(p.total_post_score, 0) AS total_post_score,
       COALESCE(p.avg_post_score, 0) AS avg_post_score,
       COALESCE(cop.total_comments_received, 0) AS total_comments_received,
       COALESCE(cop.total_comment_score_received, 0) AS total_comment_score_received,
       COALESCE(cm.total_comments_made, 0) AS total_comments_made,
       COALESCE(v.total_votes_cast, 0) AS total_votes_cast,
       COALESCE(v.total_upvotes_given, 0) AS total_upvotes_given,
       COALESCE(v.total_bounty_given, 0) AS total_bounty_given,
       COALESCE(b.total_badges, 0) AS total_badges,
       COALESCE(ph.total_edits, 0) AS total_edits,
       COALESCE(t.total_tags_in_owned_posts, 0) AS total_tags_in_owned_posts,
       COALESCE(pl_out.total_outgoing_links, 0) AS total_outgoing_links,
       COALESCE(pl_in.total_incoming_links, 0) AS total_incoming_links
FROM user_base u
LEFT JOIN posts_agg p                     ON p.user_id = u.id
LEFT JOIN comments_on_posts_agg cop        ON cop.user_id = u.id
LEFT JOIN comments_made_agg cm             ON cm.user_id = u.id
LEFT JOIN votes_cast_agg v                 ON v.user_id = u.id
LEFT JOIN badges_agg b                     ON b.user_id = u.id
LEFT JOIN posthistory_agg ph               ON ph.user_id = u.id
LEFT JOIN tags_agg t                       ON t.user_id = u.id
LEFT JOIN postlinks_outgoing_agg pl_out    ON pl_out.user_id = u.id
LEFT JOIN postlinks_incoming_agg pl_in     ON pl_in.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
