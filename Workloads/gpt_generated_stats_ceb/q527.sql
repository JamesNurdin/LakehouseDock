WITH post_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_post_views,
        COALESCE(SUM(p.answercount), 0) AS total_answer_count,
        COALESCE(SUM(p.commentcount), 0) AS total_comment_on_posts
    FROM posts p
    GROUP BY p.owneruserid
),
comment_stats AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
vote_stats AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_given
    FROM votes v
    GROUP BY v.userid
),
badge_stats AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
tag_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM posts p
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
posthistory_stats AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_event_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_score, 0) AS total_post_score,
    COALESCE(ps.total_post_views, 0) AS total_post_views,
    COALESCE(ps.total_answer_count, 0) AS total_answer_count,
    COALESCE(ps.total_comment_on_posts, 0) AS total_comment_on_posts,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_score, 0) AS total_comment_score,
    COALESCE(vs.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vs.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(vs.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(vs.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(bs.badge_count, 0) AS badge_count,
    COALESCE(ts.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(phs.posthistory_event_count, 0) AS posthistory_event_count
FROM users u
LEFT JOIN post_stats ps
    ON ps.user_id = u.id
LEFT JOIN comment_stats cs
    ON cs.user_id = u.id
LEFT JOIN vote_stats vs
    ON vs.user_id = u.id
LEFT JOIN badge_stats bs
    ON bs.user_id = u.id
LEFT JOIN tag_stats ts
    ON ts.user_id = u.id
LEFT JOIN posthistory_stats phs
    ON phs.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
