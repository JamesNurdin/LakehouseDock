WITH user_base AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate AS user_creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM users u
),
user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS post_score_sum,
        SUM(p.viewcount) AS post_viewcount_sum,
        SUM(p.answercount) AS post_answercount_sum,
        SUM(p.commentcount) AS post_commentcount_sum,
        SUM(p.favoritecount) AS post_favoritecount_sum
    FROM posts p
    GROUP BY p.owneruserid
),
user_edits AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_cast_count,
        SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS bounty_amount_sum
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_event_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tag_counts AS (
    SELECT
        p.owneruserid AS user_id,
        SUM(t.count) AS total_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    ub.user_id,
    ub.reputation,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_viewcount_sum, 0) AS post_viewcount_sum,
    COALESCE(up.post_answercount_sum, 0) AS post_answercount_sum,
    COALESCE(up.post_commentcount_sum, 0) AS post_commentcount_sum,
    COALESCE(up.post_favoritecount_sum, 0) AS post_favoritecount_sum,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(uv.bounty_amount_sum, 0) AS bounty_amount_sum,
    COALESCE(ubad.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_event_count, 0) AS posthistory_event_count,
    COALESCE(ul.postlink_count, 0) AS postlink_count,
    COALESCE(ut.total_tag_count, 0) AS total_tag_count
FROM user_base ub
LEFT JOIN user_posts up ON ub.user_id = up.user_id
LEFT JOIN user_edits ue ON ub.user_id = ue.user_id
LEFT JOIN user_comments uc ON ub.user_id = uc.user_id
LEFT JOIN user_votes uv ON ub.user_id = uv.user_id
LEFT JOIN user_badges ubad ON ub.user_id = ubad.user_id
LEFT JOIN user_posthistory uph ON ub.user_id = uph.user_id
LEFT JOIN user_postlinks ul ON ub.user_id = ul.user_id
LEFT JOIN user_tag_counts ut ON ub.user_id = ut.user_id
ORDER BY post_count DESC, comment_count DESC
LIMIT 100
