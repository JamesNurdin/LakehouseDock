WITH tag_posts_agg AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.id) AS post_cnt,
        SUM(p.score) AS post_score_sum,
        SUM(p.viewcount) AS post_view_sum,
        SUM(p.answercount) AS post_answer_sum,
        SUM(p.favoritecount) AS post_favorite_sum
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY t.id
),

-- distinct owners per tag so reputation isn’t double‑counted
tag_owners_raw AS (
    SELECT DISTINCT
        t.id AS tag_id,
        u.id AS user_id,
        u.reputation AS reputation
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN users u ON p.owneruserid = u.id
),

tag_owners_agg AS (
    SELECT
        tag_id,
        COUNT(user_id) AS owner_user_cnt,
        SUM(reputation) AS owners_total_reputation
    FROM tag_owners_raw
    GROUP BY tag_id
),

tag_comments_agg AS (
    SELECT
        t.id AS tag_id,
        COUNT(c.id) AS comment_cnt,
        SUM(c.score) AS comment_score_sum
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN comments c ON c.postid = p.id
    GROUP BY t.id
),

tag_votes_agg AS (
    SELECT
        t.id AS tag_id,
        COUNT(v.id) AS vote_cnt,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cnt
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN votes v ON v.postid = p.id
    GROUP BY t.id
),

tag_badges_agg AS (
    SELECT
        t.id AS tag_id,
        COUNT(b.id) AS badge_cnt,
        COUNT(DISTINCT b.userid) AS badge_user_cnt
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN users u ON p.owneruserid = u.id
    JOIN badges b ON b.userid = u.id
    GROUP BY t.id
)
SELECT
    tp.tag_id,
    t."count" AS tag_total_count,
    tp.post_cnt,
    tp.post_score_sum,
    tp.post_view_sum,
    tp.post_answer_sum,
    tp.post_favorite_sum,
    towner.owner_user_cnt,
    towner.owners_total_reputation,
    tc.comment_cnt,
    tc.comment_score_sum,
    tv.vote_cnt,
    tv.upvote_cnt,
    tv.downvote_cnt,
    tb.badge_cnt,
    tb.badge_user_cnt,
    (tp.post_score_sum + COALESCE(tc.comment_score_sum, 0) + COALESCE(tv.upvote_cnt, 0)) AS activity_score
FROM tag_posts_agg tp
JOIN tags t ON t.id = tp.tag_id
LEFT JOIN tag_owners_agg towner ON towner.tag_id = tp.tag_id
LEFT JOIN tag_comments_agg tc ON tc.tag_id = tp.tag_id
LEFT JOIN tag_votes_agg tv ON tv.tag_id = tp.tag_id
LEFT JOIN tag_badges_agg tb ON tb.tag_id = tp.tag_id
ORDER BY activity_score DESC
LIMIT 10
