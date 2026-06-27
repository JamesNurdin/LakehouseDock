WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            COALESCE(SUM(p.score), 0) AS post_score_sum,
            COALESCE(SUM(p.viewcount), 0) AS post_view_sum,
            COALESCE(SUM(p.answercount), 0) AS answer_count_sum,
            COALESCE(SUM(p.commentcount), 0) AS comment_count_sum,
            COALESCE(SUM(p.favoritecount), 0) AS favorite_count_sum
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comment_written_count,
            COALESCE(SUM(c.score), 0) AS comment_score_sum
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes_given AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS votes_given_count,
            COALESCE(SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END), 0) AS bounty_given_sum
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received_count,
            COALESCE(SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END), 0) AS bounty_received_sum
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS distinct_tag_count,
            COALESCE(SUM(t.count), 0) AS tag_use_sum
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
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
    user_links AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(up.answer_count_sum, 0) AS answer_count_sum,
    COALESCE(up.comment_count_sum, 0) AS post_comment_count,
    COALESCE(uc.comment_written_count, 0) AS comment_written_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvg.votes_given_count, 0) AS votes_given_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(ut.tag_use_sum, 0) AS tag_use_sum,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ul.postlink_count, 0) AS postlink_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    (
        COALESCE(up.post_score_sum, 0) * 2
        + COALESCE(uc.comment_score_sum, 0)
        + COALESCE(uvr.votes_received_count, 0)
        + COALESCE(ub.badge_count, 0) * 3
    ) AS contribution_score
FROM users u
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN user_comments uc ON u.id = uc.user_id
LEFT JOIN user_votes_given uvg ON u.id = uvg.user_id
LEFT JOIN user_votes_received uvr ON u.id = uvr.user_id
LEFT JOIN user_badges ub ON u.id = ub.user_id
LEFT JOIN user_tags ut ON u.id = ut.user_id
LEFT JOIN user_edits ue ON u.id = ue.user_id
LEFT JOIN user_links ul ON u.id = ul.user_id
LEFT JOIN user_posthistory uph ON u.id = uph.user_id
ORDER BY contribution_score DESC
LIMIT 10
