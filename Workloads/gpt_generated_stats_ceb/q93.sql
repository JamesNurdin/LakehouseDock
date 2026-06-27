WITH user_base AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM users u
    WHERE u.reputation > 1000
),
posts_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_posts,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_post_views,
        SUM(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS total_questions,
        SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers
    FROM posts p
    GROUP BY p.owneruserid
),
comments_agg AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS total_comments_made,
        SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
votes_cast_agg AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS total_votes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_given,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_given
    FROM votes v
    GROUP BY v.userid
),
votes_received_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS total_votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p
        ON v.postid = p.id
    GROUP BY p.owneruserid
),
badges_agg AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS total_badges
    FROM badges b
    GROUP BY b.userid
),
posthistory_agg AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS total_post_edits
    FROM posthistory ph
    GROUP BY ph.userid
),
postlinks_out_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS total_post_links_out
    FROM postlinks pl
    JOIN posts p
        ON pl.postid = p.id
    GROUP BY p.owneruserid
),
postlinks_in_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS total_post_links_in
    FROM postlinks pl
    JOIN posts p
        ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
),
tags_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(t.id) AS total_tag_excerpts
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    ub.user_id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(pa.total_posts, 0) AS total_posts,
    COALESCE(pa.total_questions, 0) AS total_questions,
    COALESCE(pa.total_answers, 0) AS total_answers,
    COALESCE(pa.total_post_score, 0) AS total_post_score,
    COALESCE(pa.avg_post_score, 0) AS avg_post_score,
    COALESCE(pa.total_post_views, 0) AS total_post_views,
    COALESCE(ca.total_comments_made, 0) AS total_comments_made,
    COALESCE(ca.total_comment_score, 0) AS total_comment_score,
    COALESCE(vca.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vca.upvotes_given, 0) AS upvotes_given,
    COALESCE(vca.downvotes_given, 0) AS downvotes_given,
    COALESCE(vra.total_votes_received, 0) AS total_votes_received,
    COALESCE(vra.upvotes_received, 0) AS upvotes_received,
    COALESCE(vra.downvotes_received, 0) AS downvotes_received,
    COALESCE(ba.total_badges, 0) AS total_badges,
    COALESCE(pha.total_post_edits, 0) AS total_post_edits,
    COALESCE(plo.total_post_links_out, 0) AS total_post_links_out,
    COALESCE(pli.total_post_links_in, 0) AS total_post_links_in,
    COALESCE(ta.total_tag_excerpts, 0) AS total_tag_excerpts
FROM user_base ub
LEFT JOIN posts_agg pa
    ON ub.user_id = pa.user_id
LEFT JOIN comments_agg ca
    ON ub.user_id = ca.user_id
LEFT JOIN votes_cast_agg vca
    ON ub.user_id = vca.user_id
LEFT JOIN votes_received_agg vra
    ON ub.user_id = vra.user_id
LEFT JOIN badges_agg ba
    ON ub.user_id = ba.user_id
LEFT JOIN posthistory_agg pha
    ON ub.user_id = pha.user_id
LEFT JOIN postlinks_out_agg plo
    ON ub.user_id = plo.user_id
LEFT JOIN postlinks_in_agg pli
    ON ub.user_id = pli.user_id
LEFT JOIN tags_agg ta
    ON ub.user_id = ta.user_id
ORDER BY total_post_score DESC
LIMIT 50
