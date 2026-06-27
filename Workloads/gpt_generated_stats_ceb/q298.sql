WITH posts_agg AS (
    SELECT
        CAST(date_trunc('month', p.creationdate) AS DATE) AS month,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_viewcount,
        AVG(p.answercount) AS avg_answer_count,
        AVG(p.commentcount) AS avg_comment_count,
        SUM(p.favoritecount) AS total_favorite_count,
        COUNT(DISTINCT p.owneruserid) AS distinct_owner_user_count,
        COUNT(DISTINCT p.lasteditoruserid) AS distinct_last_editor_user_count
    FROM posts p
    GROUP BY CAST(date_trunc('month', p.creationdate) AS DATE)
),
comments_agg AS (
    SELECT
        CAST(date_trunc('month', p.creationdate) AS DATE) AS month,
        COUNT(*) AS comment_count,
        AVG(c.score) AS avg_comment_score
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY CAST(date_trunc('month', p.creationdate) AS DATE)
),
votes_agg AS (
    SELECT
        CAST(date_trunc('month', p.creationdate) AS DATE) AS month,
        COUNT(*) AS vote_count,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_amount,
        COUNT(DISTINCT v.userid) AS distinct_voter_user_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY CAST(date_trunc('month', p.creationdate) AS DATE)
),
tags_agg AS (
    SELECT
        CAST(date_trunc('month', p.creationdate) AS DATE) AS month,
        COUNT(DISTINCT t.id) AS distinct_tag_count,
        SUM(t.count) AS total_tag_occurrences
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY CAST(date_trunc('month', p.creationdate) AS DATE)
),
badges_agg AS (
    SELECT
        CAST(date_trunc('month', p.creationdate) AS DATE) AS month,
        COUNT(b.id) AS badge_count
    FROM badges b
    JOIN users u ON b.userid = u.id
    JOIN posts p ON p.owneruserid = u.id
    GROUP BY CAST(date_trunc('month', p.creationdate) AS DATE)
),
posthistory_agg AS (
    SELECT
        CAST(date_trunc('month', p.creationdate) AS DATE) AS month,
        COUNT(ph.id) AS posthistory_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY CAST(date_trunc('month', p.creationdate) AS DATE)
)
SELECT
    COALESCE(p.month, c.month, v.month, t.month, b.month, ph.month) AS month,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.avg_answer_count, 0) AS avg_answer_count,
    COALESCE(p.avg_comment_count, 0) AS avg_comment_count,
    COALESCE(p.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(p.distinct_owner_user_count, 0) AS distinct_owner_user_count,
    COALESCE(p.distinct_last_editor_user_count, 0) AS distinct_last_editor_user_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(v.distinct_voter_user_count, 0) AS distinct_voter_user_count,
    COALESCE(t.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(t.total_tag_occurrences, 0) AS total_tag_occurrences,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count
FROM posts_agg p
FULL OUTER JOIN comments_agg c ON p.month = c.month
FULL OUTER JOIN votes_agg v ON COALESCE(p.month, c.month) = v.month
FULL OUTER JOIN tags_agg t ON COALESCE(p.month, c.month, v.month) = t.month
FULL OUTER JOIN badges_agg b ON COALESCE(p.month, c.month, v.month, t.month) = b.month
FULL OUTER JOIN posthistory_agg ph ON COALESCE(p.month, c.month, v.month, t.month, b.month) = ph.month
ORDER BY month
