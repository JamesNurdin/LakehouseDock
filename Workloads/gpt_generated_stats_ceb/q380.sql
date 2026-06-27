WITH user_posts AS (
    SELECT
        posts.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(posts.score) AS total_post_score,
        SUM(posts.viewcount) AS total_viewcount,
        AVG(posts.score) AS avg_post_score
    FROM posts
    GROUP BY posts.owneruserid
),
user_questions AS (
    SELECT
        posts.owneruserid AS user_id,
        COUNT(*) AS question_count
    FROM posts
    WHERE posts.posttypeid = 1
    GROUP BY posts.owneruserid
),
user_answers AS (
    SELECT
        posts.owneruserid AS user_id,
        COUNT(*) AS answer_count
    FROM posts
    WHERE posts.posttypeid = 2
    GROUP BY posts.owneruserid
),
user_comments AS (
    SELECT
        comments.userid AS user_id,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY comments.userid
),
user_votes AS (
    SELECT
        votes.userid AS user_id,
        COUNT(*) AS vote_count
    FROM votes
    GROUP BY votes.userid
),
user_badges AS (
    SELECT
        badges.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY badges.userid
),
user_edits AS (
    SELECT
        posts.lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts
    GROUP BY posts.lasteditoruserid
),
user_posthistory AS (
    SELECT
        posthistory.userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY posthistory.userid
),
user_tagged_posts AS (
    SELECT
        posts.owneruserid AS user_id,
        COUNT(DISTINCT tags.id) AS distinct_tag_count
    FROM posts
    JOIN tags ON tags.excerptpostid = posts.id
    GROUP BY posts.owneruserid
),
user_links AS (
    SELECT
        posts.owneruserid AS user_id,
        COUNT(*) AS link_count
    FROM posts
    JOIN postlinks ON postlinks.postid = posts.id
    GROUP BY posts.owneruserid
)
SELECT
    users.id AS user_id,
    users.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(upq.question_count, 0) AS question_count,
    COALESCE(upa.answer_count, 0) AS answer_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(ul.link_count, 0) AS link_count
FROM users
LEFT JOIN user_posts up ON up.user_id = users.id
LEFT JOIN user_questions upq ON upq.user_id = users.id
LEFT JOIN user_answers upa ON upa.user_id = users.id
LEFT JOIN user_comments uc ON uc.user_id = users.id
LEFT JOIN user_votes uv ON uv.user_id = users.id
LEFT JOIN user_badges ub ON ub.user_id = users.id
LEFT JOIN user_edits ue ON ue.user_id = users.id
LEFT JOIN user_posthistory uph ON uph.user_id = users.id
LEFT JOIN user_tagged_posts ut ON ut.user_id = users.id
LEFT JOIN user_links ul ON ul.user_id = users.id
ORDER BY users.reputation DESC
LIMIT 100
