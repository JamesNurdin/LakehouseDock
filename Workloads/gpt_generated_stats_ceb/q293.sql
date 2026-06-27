WITH user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS total_posts,
           COALESCE(SUM(score), 0) AS total_post_score,
           COALESCE(SUM(viewcount), 0) AS total_views,
           COALESCE(SUM(answercount), 0) AS total_answers,
           COALESCE(SUM(commentcount), 0) AS total_comments_on_posts,
           COALESCE(SUM(favoritecount), 0) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_comments_made,
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
           COUNT(v.id) AS total_votes_received
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
user_tags AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS total_tags
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_edits_by_user AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_edits_by_user
    FROM posthistory
    GROUP BY userid
),
user_edits_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(ph.id) AS total_edits_received_on_posts
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_out AS (
    SELECT p.owneruserid AS user_id,
           COUNT(pl.id) AS total_outgoing_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_in AS (
    SELECT p.owneruserid AS user_id,
           COUNT(pl.id) AS total_incoming_links
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.total_posts, 0) AS total_posts,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_views, 0) AS total_views,
       COALESCE(up.total_answers, 0) AS total_answers,
       COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
       COALESCE(up.total_favorites, 0) AS total_favorites,
       COALESCE(uc.total_comments_made, 0) AS total_comments_made,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uvc.total_votes_cast, 0) AS total_votes_cast,
       COALESCE(uvr.total_votes_received, 0) AS total_votes_received,
       COALESCE(ub.total_badges, 0) AS total_badges,
       COALESCE(ut.total_tags, 0) AS total_tags,
       COALESCE(ue.total_edits_by_user, 0) AS total_edits_by_user,
       COALESCE(uer.total_edits_received_on_posts, 0) AS total_edits_received_on_posts,
       COALESCE(uplo.total_outgoing_links, 0) AS total_outgoing_links,
       COALESCE(upli.total_incoming_links, 0) AS total_incoming_links
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_edits_by_user ue ON ue.user_id = u.id
LEFT JOIN user_edits_received uer ON uer.user_id = u.id
LEFT JOIN user_postlinks_out uplo ON uplo.user_id = u.id
LEFT JOIN user_postlinks_in upli ON upli.user_id = u.id
ORDER BY total_posts DESC, total_votes_received DESC
LIMIT 100
