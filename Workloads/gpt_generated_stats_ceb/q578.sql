WITH user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           SUM(viewcount) AS total_viewcount,
           SUM(answercount) AS total_answer_count,
           SUM(commentcount) AS total_comment_count,
           SUM(favoritecount) AS total_favorite_count
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
user_votes AS (
    SELECT userid AS user_id,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
           SUM(COALESCE(bountyamount, 0)) AS total_bounty_given
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT userid AS user_id,
           COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),
user_links AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_aggregated AS (
    SELECT u.id,
           u.reputation,
           COALESCE(p.post_count, 0) AS post_count,
           COALESCE(p.total_post_score, 0) AS total_post_score,
           COALESCE(p.total_viewcount, 0) AS total_viewcount,
           COALESCE(p.total_answer_count, 0) AS total_answer_count,
           COALESCE(p.total_comment_count, 0) AS total_comment_count,
           COALESCE(p.total_favorite_count, 0) AS total_favorite_count,
           COALESCE(c.comment_count, 0) AS comment_count,
           COALESCE(c.total_comment_score, 0) AS total_comment_score,
           COALESCE(v.vote_count, 0) AS vote_count,
           COALESCE(v.upvote_count, 0) AS upvote_count,
           COALESCE(v.downvote_count, 0) AS downvote_count,
           COALESCE(v.total_bounty_given, 0) AS total_bounty_given,
           COALESCE(b.badge_count, 0) AS badge_count,
           COALESCE(e.edit_count, 0) AS edit_count,
           COALESCE(l.link_count, 0) AS link_count,
           COALESCE(tg.tag_count, 0) AS tag_count
    FROM users u
    LEFT JOIN user_posts p   ON p.user_id = u.id
    LEFT JOIN user_comments c ON c.user_id = u.id
    LEFT JOIN user_votes v    ON v.user_id = u.id
    LEFT JOIN user_badges b   ON b.user_id = u.id
    LEFT JOIN user_edits e    ON e.user_id = u.id
    LEFT JOIN user_links l    ON l.user_id = u.id
    LEFT JOIN user_tags tg    ON tg.user_id = u.id
)
SELECT id,
       reputation,
       post_count,
       total_post_score,
       total_viewcount,
       total_answer_count,
       total_comment_count,
       total_favorite_count,
       comment_count,
       total_comment_score,
       vote_count,
       upvote_count,
       downvote_count,
       total_bounty_given,
       badge_count,
       edit_count,
       link_count,
       tag_count,
       CASE WHEN post_count > 0 THEN total_post_score * 1.0 / post_count END AS avg_post_score,
       CASE WHEN comment_count > 0 THEN total_comment_score * 1.0 / comment_count END AS avg_comment_score,
       CASE WHEN vote_count > 0 THEN upvote_count * 1.0 / vote_count END AS upvote_ratio,
       CASE WHEN post_count > 0 THEN total_viewcount * 1.0 / post_count END AS avg_views_per_post,
       CASE WHEN post_count > 0 THEN tag_count * 1.0 / post_count END AS avg_tags_per_post
FROM user_aggregated
WHERE (post_count + comment_count + vote_count) > 0
ORDER BY reputation DESC
LIMIT 100
