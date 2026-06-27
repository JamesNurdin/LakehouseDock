WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
        SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.score), 0) AS avg_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_view_count,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_made_count
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badges_earned
    FROM badges b
    GROUP BY b.userid
),
user_edits AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS edits_made
    FROM posthistory ph
    GROUP BY ph.userid
),
user_links AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT pl.id) AS linked_posts_count
    FROM posts p
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tag_count,
        COALESCE(SUM(t.count), 0) AS tag_use_sum
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.question_count, 0) AS question_count,
    COALESCE(up.answer_count, 0) AS answer_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.comment_made_count, 0) AS comment_made_count,
    COALESCE(uv.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uv.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uv.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(ub.badges_earned, 0) AS badges_earned,
    COALESCE(ue.edits_made, 0) AS edits_made,
    COALESCE(ul.linked_posts_count, 0) AS linked_posts_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(ut.tag_use_sum, 0) AS tag_use_sum
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_links ul ON ul.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 50
