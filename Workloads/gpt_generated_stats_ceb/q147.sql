WITH
    user_posts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score,
            AVG(p.score) AS avg_post_score,
            SUM(p.viewcount) AS total_post_views,
            AVG(p.viewcount) AS avg_post_views,
            SUM(p.answercount) AS total_answers,
            AVG(p.answercount) AS avg_answers,
            MIN(p.creationdate) AS first_post_date,
            MAX(p.creationdate) AS last_post_date
        FROM posts p
        GROUP BY p.owneruserid
    ),
    post_comments AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(c.id) AS comment_count_on_posts,
            SUM(c.score) AS comment_score_sum,
            AVG(c.score) AS avg_comment_score
        FROM posts p
        JOIN comments c ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    post_votes AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(v.id) AS vote_count,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
        FROM posts p
        JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid AS userid,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_edits AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(ph.id) AS edit_count
        FROM posts p
        JOIN posthistory ph ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_comments_authored AS (
        SELECT
            c.userid AS userid,
            COUNT(*) AS comments_authored,
            SUM(c.score) AS comment_score_authored,
            AVG(c.score) AS avg_comment_score_authored
        FROM comments c
        GROUP BY c.userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(upost.post_count, 0) AS post_count,
    COALESCE(upost.total_post_score, 0) AS total_post_score,
    COALESCE(upost.avg_post_score, 0) AS avg_post_score,
    COALESCE(upost.total_post_views, 0) AS total_post_views,
    COALESCE(upost.avg_post_views, 0) AS avg_post_views,
    COALESCE(upost.total_answers, 0) AS total_answers,
    COALESCE(upost.avg_answers, 0) AS avg_answers,
    COALESCE(pc.comment_count_on_posts, 0) AS comment_count_on_posts,
    COALESCE(pc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(pc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uca.comments_authored, 0) AS comments_authored,
    COALESCE(uca.comment_score_authored, 0) AS comment_score_authored,
    COALESCE(uca.avg_comment_score_authored, 0) AS avg_comment_score_authored,
    COALESCE(pv.vote_count, 0) AS vote_count,
    COALESCE(pv.upvote_count, 0) AS upvote_count,
    COALESCE(pv.downvote_count, 0) AS downvote_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count
FROM users u
LEFT JOIN user_posts upost ON upost.userid = u.id
LEFT JOIN post_comments pc ON pc.userid = u.id
LEFT JOIN post_votes pv ON pv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_tags ut ON ut.userid = u.id
LEFT JOIN user_comments_authored uca ON uca.userid = u.id
ORDER BY post_count DESC, total_post_score DESC
LIMIT 100
