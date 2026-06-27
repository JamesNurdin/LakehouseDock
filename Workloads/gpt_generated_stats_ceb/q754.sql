WITH post_agg AS (
    SELECT
        DATE_TRUNC('month', p.creationdate) AS month,
        COUNT(*) AS total_posts,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments_on_posts,
        SUM(p.favoritecount) AS total_favorites,
        AVG(u.reputation) AS avg_owner_reputation
    FROM posts p
    JOIN users u ON p.owneruserid = u.id
    GROUP BY DATE_TRUNC('month', p.creationdate)
),
comment_agg AS (
    SELECT
        DATE_TRUNC('month', c.creationdate) AS month,
        COUNT(*) AS total_comments
    FROM comments c
    GROUP BY DATE_TRUNC('month', c.creationdate)
),
vote_agg AS (
    SELECT
        DATE_TRUNC('month', v.creationdate) AS month,
        COUNT(*) AS total_votes,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS total_upvotes,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS total_downvotes
    FROM votes v
    GROUP BY DATE_TRUNC('month', v.creationdate)
),
tag_agg AS (
    SELECT
        DATE_TRUNC('month', p.creationdate) AS month,
        COUNT(t.id) AS total_tags
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY DATE_TRUNC('month', p.creationdate)
)
SELECT
    pa.month,
    pa.total_posts,
    pa.total_score,
    pa.avg_score,
    pa.total_views,
    pa.total_answers,
    pa.total_comments_on_posts,
    pa.total_favorites,
    pa.avg_owner_reputation,
    COALESCE(ca.total_comments, 0) AS total_comments,
    COALESCE(va.total_votes, 0) AS total_votes,
    COALESCE(va.total_upvotes, 0) AS total_upvotes,
    COALESCE(va.total_downvotes, 0) AS total_downvotes,
    COALESCE(ta.total_tags, 0) AS total_tags
FROM post_agg pa
LEFT JOIN comment_agg ca ON pa.month = ca.month
LEFT JOIN vote_agg va ON pa.month = va.month
LEFT JOIN tag_agg ta ON pa.month = ta.month
ORDER BY pa.month
