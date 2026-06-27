WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        SUM(CASE WHEN p.posttypeid = 1 THEN p.score ELSE 0 END) AS question_score_sum,
        SUM(CASE WHEN p.posttypeid = 2 THEN p.score ELSE 0 END) AS answer_score_sum,
        SUM(p.viewcount) AS total_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.favoritecount) AS total_favorites
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast,
        SUM(v.bountyamount) AS total_bounty_awarded
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_links AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS link_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(t.id) AS tag_excerpt_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.question_score_sum, 0) AS question_score_sum,
    COALESCE(up.answer_score_sum, 0) AS answer_score_sum,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(uv.upvote_cast, 0) AS upvote_cast,
    COALESCE(uv.downvote_cast, 0) AS downvote_cast,
    COALESCE(uv.total_bounty_awarded, 0) AS total_bounty_awarded,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ul.link_count, 0) AS link_count,
    COALESCE(ut.tag_excerpt_count, 0) AS tag_excerpt_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_links ul ON ul.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
