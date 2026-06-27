WITH
post_agg AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS total_posts,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_views,
        SUM(favoritecount) AS total_favorites,
        SUM(answercount) AS total_answers_on_questions,
        COUNT(DISTINCT CASE WHEN posttypeid = 1 THEN id END) AS total_questions,
        COUNT(DISTINCT CASE WHEN posttypeid = 2 THEN id END) AS total_answers
    FROM posts
    GROUP BY owneruserid
),
comment_agg AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS total_comments,
        SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
vote_cast_agg AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS total_votes_cast,
        COUNT(CASE WHEN votetypeid = 1 THEN 1 END) AS up_votes_cast,
        COUNT(CASE WHEN votetypeid = 2 THEN 1 END) AS down_votes_cast
    FROM votes
    GROUP BY userid
),
vote_received_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_votes_received,
        COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS up_votes_received,
        COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS down_votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
badge_agg AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS total_badges
    FROM badges
    GROUP BY userid
),
posthistory_agg AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS total_posthistory
    FROM posthistory
    GROUP BY userid
),
tag_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS total_tags_used
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
postlink_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_postlinks
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    COALESCE(p.total_posts, 0) AS total_posts,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_views, 0) AS total_views,
    COALESCE(p.total_favorites, 0) AS total_favorites,
    COALESCE(p.total_answers_on_questions, 0) AS total_answers_on_questions,
    COALESCE(p.total_questions, 0) AS total_questions,
    COALESCE(p.total_answers, 0) AS total_answers,
    COALESCE(c.total_comments, 0) AS total_comments,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vc.up_votes_cast, 0) AS up_votes_cast,
    COALESCE(vc.down_votes_cast, 0) AS down_votes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(vr.up_votes_received, 0) AS up_votes_received,
    COALESCE(vr.down_votes_received, 0) AS down_votes_received,
    COALESCE(b.total_badges, 0) AS total_badges,
    COALESCE(ph.total_posthistory, 0) AS total_posthistory,
    COALESCE(t.total_tags_used, 0) AS total_tags_used,
    COALESCE(pl.total_postlinks, 0) AS total_postlinks
FROM users u
LEFT JOIN post_agg p ON p.user_id = u.id
LEFT JOIN comment_agg c ON c.user_id = u.id
LEFT JOIN vote_cast_agg vc ON vc.user_id = u.id
LEFT JOIN vote_received_agg vr ON vr.user_id = u.id
LEFT JOIN badge_agg b ON b.user_id = u.id
LEFT JOIN posthistory_agg ph ON ph.user_id = u.id
LEFT JOIN tag_agg t ON t.user_id = u.id
LEFT JOIN postlink_agg pl ON pl.user_id = u.id
ORDER BY total_posts DESC
LIMIT 100
