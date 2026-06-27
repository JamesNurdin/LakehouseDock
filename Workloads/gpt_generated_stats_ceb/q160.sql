WITH user_base AS (
    SELECT id, reputation
    FROM users
),
user_posts AS (
    SELECT owneruserid,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           AVG(score) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT userid,
           COUNT(*) AS vote_cast_count,
           SUM(votetypeid) AS vote_type_sum
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_history AS (
    SELECT userid,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_history_owned AS (
    SELECT p.owneruserid,
           COUNT(*) AS owned_posthistory_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
user_links AS (
    SELECT p.owneruserid,
           COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tagged_posts AS (
    SELECT p.owneruserid,
           COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    ub.id AS user_id,
    ub.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(uv.vote_type_sum, 0) AS vote_type_sum,
    COALESCE(ubg.badge_count, 0) AS badge_count,
    COALESCE(uh.posthistory_count, 0) AS posthistory_count,
    COALESCE(uho.owned_posthistory_count, 0) AS owned_posthistory_count,
    COALESCE(ul.postlink_count, 0) AS postlink_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    RANK() OVER (ORDER BY ub.reputation DESC) AS reputation_rank,
    ROW_NUMBER() OVER (ORDER BY COALESCE(up.total_post_score, 0) DESC) AS score_rank
FROM user_base ub
LEFT JOIN user_posts up ON up.owneruserid = ub.id
LEFT JOIN user_comments uc ON uc.userid = ub.id
LEFT JOIN user_votes uv ON uv.userid = ub.id
LEFT JOIN user_badges ubg ON ubg.userid = ub.id
LEFT JOIN user_history uh ON uh.userid = ub.id
LEFT JOIN user_history_owned uho ON uho.owneruserid = ub.id
LEFT JOIN user_links ul ON ul.owneruserid = ub.id
LEFT JOIN user_tagged_posts ut ON ut.owneruserid = ub.id
ORDER BY ub.reputation DESC
LIMIT 100
