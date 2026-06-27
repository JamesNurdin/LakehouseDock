WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_cnt,
        SUM(p.viewcount) AS total_views,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.answercount) AS total_answercount,
        SUM(p.commentcount) AS total_commentcount,
        SUM(p.favoritecount) AS total_favoritecount
    FROM posts p
    GROUP BY p.owneruserid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comments_made
    FROM comments c
    GROUP BY c.userid
),
user_badges AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badges_earned
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS userid,
        COUNT(*) AS posthistory_cnt
    FROM posthistory ph
    GROUP BY ph.userid
),
user_edits AS (
    SELECT
        p.lasteditoruserid AS userid,
        COUNT(*) AS edits_made
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS tags_used
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_cnt, 0) AS post_count,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_score, 0) AS total_score,
    COALESCE(up.avg_score, 0) AS avg_score,
    COALESCE(up.total_answercount, 0) AS total_answer_count,
    COALESCE(up.total_commentcount, 0) AS total_comment_count,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(uc.comments_made, 0) AS comments_made,
    COALESCE(ub.badges_earned, 0) AS badges_earned,
    COALESCE(uph.posthistory_cnt, 0) AS posthistory_entries,
    COALESCE(ue.edits_made, 0) AS edits_made,
    COALESCE(ut.tags_used, 0) AS tags_used
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_badges ub ON u.id = ub.userid
LEFT JOIN user_posthistory uph ON u.id = uph.userid
LEFT JOIN user_edits ue ON u.id = ue.userid
LEFT JOIN user_tags ut ON u.id = ut.userid
ORDER BY (
    COALESCE(up.post_cnt, 0) +
    COALESCE(uc.comments_made, 0) +
    COALESCE(ub.badges_earned, 0)
) DESC
LIMIT 10
