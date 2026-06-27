WITH user_posts_agg AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(p.score) AS total_score,
           AVG(p.score) AS avg_score,
           SUM(p.commentcount) AS total_comment_count,
           SUM(p.answercount) AS total_answer_count,
           SUM(p.viewcount) AS total_views
    FROM posts p
    GROUP BY p.owneruserid
),
user_edits_agg AS (
    SELECT p.lasteditoruserid AS userid,
           COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_comments_agg AS (
    SELECT c.userid AS userid,
           COUNT(*) AS comment_count,
           SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes_agg AS (
    SELECT v.userid AS userid,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count,
           SUM(v.bountyamount) AS total_bounty
    FROM votes v
    GROUP BY v.userid
),
user_outgoing_links_agg AS (
    SELECT p.owneruserid AS userid,
           COUNT(pl.id) AS outgoing_link_count
    FROM posts p
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_inbound_links_agg AS (
    SELECT p.owneruserid AS userid,
           COUNT(pl.id) AS inbound_link_count
    FROM posts p
    JOIN postlinks pl ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
),
user_tag_excerpts_agg AS (
    SELECT p.owneruserid AS userid,
           COUNT(t.id) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.total_score, 0) AS total_post_score,
       COALESCE(p.avg_score, 0) AS avg_post_score,
       COALESCE(p.total_comment_count, 0) AS total_post_comments,
       COALESCE(p.total_answer_count, 0) AS total_post_answers,
       COALESCE(p.total_views, 0) AS total_post_views,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.total_comment_score, 0) AS total_comment_score,
       COALESCE(v.vote_count, 0) AS vote_count,
       COALESCE(v.upvote_count, 0) AS upvote_count,
       COALESCE(v.downvote_count, 0) AS downvote_count,
       COALESCE(v.total_bounty, 0) AS total_bounty_amount,
       COALESCE(e.edit_count, 0) AS edit_count,
       COALESCE(l.outgoing_link_count, 0) AS outgoing_link_count,
       COALESCE(l2.inbound_link_count, 0) AS inbound_link_count,
       COALESCE(t.tag_excerpt_count, 0) AS tag_excerpt_count
FROM users u
LEFT JOIN user_posts_agg p ON p.userid = u.id
LEFT JOIN user_edits_agg e ON e.userid = u.id
LEFT JOIN user_comments_agg c ON c.userid = u.id
LEFT JOIN user_votes_agg v ON v.userid = u.id
LEFT JOIN user_outgoing_links_agg l ON l.userid = u.id
LEFT JOIN user_inbound_links_agg l2 ON l2.userid = u.id
LEFT JOIN user_tag_excerpts_agg t ON t.userid = u.id
ORDER BY total_post_score DESC, u.reputation DESC
LIMIT 100
