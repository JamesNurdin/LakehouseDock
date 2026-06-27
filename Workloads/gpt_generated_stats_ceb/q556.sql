WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        COALESCE(SUM(score), 0) AS total_post_score,
        COALESCE(AVG(score), 0) AS avg_post_score,
        COALESCE(SUM(viewcount), 0) AS total_views,
        COALESCE(SUM(answercount), 0) AS total_answers,
        COALESCE(SUM(commentcount), 0) AS total_comments_on_posts,
        COALESCE(SUM(favoritecount), 0) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        COALESCE(AVG(score), 0) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid,
        COUNT(*) AS vote_given_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_given,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_given
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT
        lasteditoruserid AS userid,
        COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
user_posthistory AS (
    SELECT
        userid,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_postlinks_out AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS postlink_out_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_in AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS postlink_in_count
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_views, 0) AS total_post_views,
    COALESCE(p.total_answers, 0) AS total_answers,
    COALESCE(p.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(p.total_favorites, 0) AS total_favorites,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(v.vote_given_count, 0) AS vote_given_count,
    COALESCE(v.upvote_given, 0) AS upvote_given,
    COALESCE(v.downvote_given, 0) AS downvote_given,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(h.posthistory_count, 0) AS posthistory_count,
    COALESCE(pl_out.postlink_out_count, 0) AS postlink_out_count,
    COALESCE(pl_in.postlink_in_count, 0) AS postlink_in_count,
    COALESCE(t.tag_excerpt_count, 0) AS tag_excerpt_count,
    (
        COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0) + COALESCE(v.vote_given_count, 0) +
        COALESCE(b.badge_count, 0) + COALESCE(e.edit_count, 0) + COALESCE(h.posthistory_count, 0) +
        COALESCE(pl_out.postlink_out_count, 0) + COALESCE(pl_in.postlink_in_count, 0) +
        COALESCE(t.tag_excerpt_count, 0)
    ) AS total_activity
FROM users u
LEFT JOIN user_posts p ON u.id = p.userid
LEFT JOIN user_comments c ON u.id = c.userid
LEFT JOIN user_votes v ON u.id = v.userid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_edits e ON u.id = e.userid
LEFT JOIN user_posthistory h ON u.id = h.userid
LEFT JOIN user_postlinks_out pl_out ON u.id = pl_out.userid
LEFT JOIN user_postlinks_in pl_in ON u.id = pl_in.userid
LEFT JOIN user_tags t ON u.id = t.userid
ORDER BY total_activity DESC
LIMIT 10
