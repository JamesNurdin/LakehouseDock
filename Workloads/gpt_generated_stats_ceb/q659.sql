WITH tag_excerpts AS (
    SELECT
        t.id AS tag_id,
        t.count AS tag_use_count,
        p.id AS post_id,
        p.score AS post_score,
        p.viewcount AS post_viewcount,
        p.answercount AS post_answercount,
        p.commentcount AS post_commentcount,
        p.favoritecount AS post_favoritecount,
        p.owneruserid AS post_owner_userid
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
),
comment_agg AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score_sum
    FROM comments c
    GROUP BY c.postid
),
vote_agg AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount,
        COUNT(DISTINCT v.userid) AS distinct_voter_count
    FROM votes v
    GROUP BY v.postid
),
owner_badge_agg AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
)
SELECT
    te.tag_id,
    te.tag_use_count,
    te.post_score,
    te.post_viewcount,
    te.post_answercount,
    te.post_commentcount,
    te.post_favoritecount,
    owner.reputation,
    owner.upvotes,
    owner.downvotes,
    owner.views,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(va.vote_count, 0) AS vote_count,
    COALESCE(va.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(va.distinct_voter_count, 0) AS distinct_voter_count,
    COALESCE(ob.badge_count, 0) AS owner_badge_count
FROM tag_excerpts te
LEFT JOIN users owner
    ON te.post_owner_userid = owner.id
LEFT JOIN comment_agg ca
    ON ca.post_id = te.post_id
LEFT JOIN vote_agg va
    ON va.post_id = te.post_id
LEFT JOIN owner_badge_agg ob
    ON ob.user_id = owner.id
ORDER BY te.tag_use_count DESC
LIMIT 100
