WITH user_posts AS (
    SELECT
        posts.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(posts.score) AS total_post_score,
        SUM(posts.viewcount) AS total_viewcount,
        SUM(posts.answercount) AS total_answer_count
    FROM posts
    GROUP BY posts.owneruserid
),
user_comments AS (
    SELECT
        comments.userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(comments.score) AS comment_score_sum
    FROM comments
    GROUP BY comments.userid
),
user_badges AS (
    SELECT
        badges.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY badges.userid
),
user_votes_cast AS (
    SELECT
        votes.userid AS user_id,
        COUNT(*) AS votes_cast_count
    FROM votes
    GROUP BY votes.userid
),
user_votes_received AS (
    SELECT
        posts.owneruserid AS user_id,
        COUNT(*) AS votes_received_count
    FROM votes
    JOIN posts ON votes.postid = posts.id
    GROUP BY posts.owneruserid
),
user_posthistory AS (
    SELECT
        posthistory.userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY posthistory.userid
),
user_linked_posts AS (
    SELECT
        posts.owneruserid AS user_id,
        COUNT(*) AS linked_posts_count
    FROM postlinks
    JOIN posts ON postlinks.postid = posts.id
    GROUP BY posts.owneruserid
),
user_tags_used AS (
    SELECT
        posts.owneruserid AS user_id,
        COUNT(DISTINCT tags.id) AS distinct_tags_used
    FROM tags
    JOIN posts ON tags.excerptpostid = posts.id
    GROUP BY posts.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.total_answer_count, 0) AS total_answer_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(lp.linked_posts_count, 0) AS linked_posts_count,
    COALESCE(t.distinct_tags_used, 0) AS distinct_tags_used
FROM users u
LEFT JOIN user_posts p ON p.user_id = u.id
LEFT JOIN user_comments c ON c.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_posthistory ph ON ph.user_id = u.id
LEFT JOIN user_linked_posts lp ON lp.user_id = u.id
LEFT JOIN user_tags_used t ON t.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
