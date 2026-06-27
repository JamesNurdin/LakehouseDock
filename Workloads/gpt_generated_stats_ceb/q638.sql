WITH post_agg AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.answercount) AS total_answercount,
        SUM(p.commentcount) AS total_post_commentcount,
        SUM(p.favoritecount) AS total_favoritecount
    FROM posts p
    GROUP BY p.owneruserid
),
comment_agg AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count,
        SUM(c.score) AS total_comment_score,
        AVG(c.score) AS avg_comment_score
    FROM comments c
    GROUP BY c.userid
),
vote_agg AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(v.bountyamount) AS total_bounty_amount
    FROM votes v
    GROUP BY v.userid
),
badge_agg AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
tag_agg AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0.0) AS avg_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.total_answercount, 0) AS total_answercount,
    COALESCE(p.total_post_commentcount, 0) AS total_post_commentcount,
    COALESCE(p.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(c.avg_comment_score, 0.0) AS avg_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(v.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(tg.distinct_tag_count, 0) AS distinct_tag_count
FROM users u
LEFT JOIN post_agg p   ON p.userid   = u.id
LEFT JOIN comment_agg c ON c.userid   = u.id
LEFT JOIN vote_agg v    ON v.userid   = u.id
LEFT JOIN badge_agg b   ON b.userid   = u.id
LEFT JOIN tag_agg tg    ON tg.userid  = u.id
ORDER BY u.reputation DESC
LIMIT 100
