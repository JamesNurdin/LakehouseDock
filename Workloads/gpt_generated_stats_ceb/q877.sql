WITH user_posts AS (
        SELECT owneruserid AS user_id,
               COUNT(*) AS post_count,
               SUM(score) AS total_post_score,
               AVG(score) AS avg_post_score,
               SUM(viewcount) AS total_views,
               SUM(answercount) AS total_answers,
               SUM(commentcount) AS total_comments_on_posts,
               SUM(favoritecount) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT userid AS user_id,
               COUNT(*) AS comment_count,
               SUM(score) AS total_comment_score,
               AVG(score) AS avg_comment_score
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
               COUNT(*) AS badge_count,
               MIN(date) AS first_badge_date,
               MAX(date) AS last_badge_date
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT userid AS user_id,
               COUNT(*) AS edit_count
        FROM posthistory
        GROUP BY userid
    ),
    user_tags AS (
        SELECT p.owneruserid AS user_id,
               COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_links AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS post_link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.avg_post_score, 0) AS avg_post_score,
       COALESCE(up.total_views, 0) AS total_views,
       COALESCE(up.total_answers, 0) AS total_answers,
       COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
       COALESCE(up.total_favorites, 0) AS total_favorites,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
       COALESCE(uv.vote_count, 0) AS vote_count,
       COALESCE(uv.upvote_count, 0) AS upvote_count,
       COALESCE(uv.downvote_count, 0) AS downvote_count,
       COALESCE(uv.total_bounty_given, 0) AS total_bounty_given,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ue.edit_count, 0) AS edit_count,
       COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(ul.post_link_count, 0) AS post_link_count,
       ub.first_badge_date,
       ub.last_badge_date
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_links ul ON ul.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
