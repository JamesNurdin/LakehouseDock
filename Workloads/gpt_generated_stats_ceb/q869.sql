WITH
    badge_counts AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    post_counts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) FILTER (WHERE p.posttypeid = 1) AS question_count,
            COUNT(*) FILTER (WHERE p.posttypeid = 2) AS answer_count,
            AVG(p.score) AS avg_post_score,
            SUM(p.viewcount) AS total_post_views
        FROM posts p
        GROUP BY p.owneruserid
    ),
    votes_cast AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS votes_cast_count
        FROM votes v
        GROUP BY v.userid
    ),
    votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received_count,
            COALESCE(SUM(v.bountyamount), 0) AS bounty_received_total
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    edits_made AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS edits_made_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    edits_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS edits_received_count
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    user_base AS (
        SELECT
            u.id AS user_id,
            u.reputation
        FROM users u
    )
SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(bc.badge_count, 0)               AS badge_count,
    COALESCE(pc.question_count, 0)            AS question_count,
    COALESCE(pc.answer_count, 0)              AS answer_count,
    COALESCE(pc.avg_post_score, 0)            AS avg_post_score,
    COALESCE(pc.total_post_views, 0)          AS total_post_views,
    COALESCE(vc.votes_cast_count, 0)          AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0)     AS votes_received_count,
    COALESCE(vr.bounty_received_total, 0)    AS bounty_received_total,
    COALESCE(em.edits_made_count, 0)          AS edits_made_count,
    COALESCE(er.edits_received_count, 0)     AS edits_received_count
FROM user_base ub
LEFT JOIN badge_counts bc          ON bc.user_id = ub.user_id
LEFT JOIN post_counts pc          ON pc.user_id = ub.user_id
LEFT JOIN votes_cast vc           ON vc.user_id = ub.user_id
LEFT JOIN votes_received vr       ON vr.user_id = ub.user_id
LEFT JOIN edits_made em           ON em.user_id = ub.user_id
LEFT JOIN edits_received er       ON er.user_id = ub.user_id
ORDER BY badge_count DESC, ub.user_id
LIMIT 100
