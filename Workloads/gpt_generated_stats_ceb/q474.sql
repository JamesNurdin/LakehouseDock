WITH tag_posts_agg AS (
    SELECT
        t.id AS tag_id,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_viewcount,
        AVG(p.viewcount) AS avg_viewcount,
        COUNT(DISTINCT p.owneruserid) AS distinct_owner_user_count
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
    GROUP BY t.id
),
tag_comments_agg AS (
    SELECT
        t.id AS tag_id,
        COUNT(c.id) AS comment_count,
        COUNT(DISTINCT c.userid) AS distinct_commenter_user_count
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY t.id
),
tag_votes_agg AS (
    SELECT
        t.id AS tag_id,
        COUNT(v.id) AS vote_count,
        COUNT(DISTINCT v.userid) AS distinct_voter_user_count
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY t.id
),
tag_owner_reputation_agg AS (
    SELECT
        t.id AS tag_id,
        SUM(u.reputation) AS total_owner_reputation
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
    JOIN users u
        ON p.owneruserid = u.id
    GROUP BY t.id
)
SELECT
    tp.tag_id,
    tp.post_count,
    tp.total_post_score,
    tp.avg_post_score,
    tp.total_viewcount,
    tp.avg_viewcount,
    tp.distinct_owner_user_count,
    tc.comment_count,
    tc.distinct_commenter_user_count,
    tv.vote_count,
    tv.distinct_voter_user_count,
    tr.total_owner_reputation
FROM tag_posts_agg tp
LEFT JOIN tag_comments_agg tc
    ON tc.tag_id = tp.tag_id
LEFT JOIN tag_votes_agg tv
    ON tv.tag_id = tp.tag_id
LEFT JOIN tag_owner_reputation_agg tr
    ON tr.tag_id = tp.tag_id
ORDER BY tp.post_count DESC
LIMIT 20
