WITH user_posts AS (
    SELECT owneruserid,
           COUNT(*) AS post_count,
           AVG(score) AS avg_score,
           SUM(answercount) AS total_answers,
           SUM(commentcount) AS total_comments_on_posts,
           SUM(viewcount) AS total_views,
           SUM(favoritecount) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT userid,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT userid,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_postlinks AS (
    SELECT p.owneruserid AS owneruserid,
           COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tag_excerpts AS (
    SELECT p.owneruserid AS owneruserid,
           COUNT(*) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    u.views AS user_views,
    u.upvotes AS user_upvotes,
    u.downvotes AS user_downvotes,
    COALESCE(up.post_count, 0) AS total_posts,
    COALESCE(up.avg_score, 0) AS avg_post_score,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(up.total_views, 0) AS total_post_views,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uc.comment_count, 0) AS total_comments_made,
    COALESCE(uc.comment_score_sum, 0) AS total_comment_score,
    COALESCE(uv.vote_count, 0) AS total_votes_cast,
    COALESCE(uv.upvote_cast, 0) AS upvotes_cast,
    COALESCE(uv.downvote_cast, 0) AS downvotes_cast,
    COALESCE(ub.badge_count, 0) AS total_badges,
    COALESCE(uph.posthistory_count, 0) AS total_posthistory_events,
    COALESCE(ulp.postlink_count, 0) AS total_post_links,
    COALESCE(ute.tag_excerpt_count, 0) AS total_tag_excerpts
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_postlinks ulp ON ulp.owneruserid = u.id
LEFT JOIN user_tag_excerpts ute ON ute.owneruserid = u.id
ORDER BY total_posts DESC, u.reputation DESC
LIMIT 100
