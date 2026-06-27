WITH
    tag_posts AS (
        SELECT
            t.id AS tag_id,
            p.id AS post_id,
            p.score,
            p.viewcount,
            p.owneruserid
        FROM tags t
        JOIN posts p
            ON t.excerptpostid = p.id
    ),
    post_comment_counts AS (
        SELECT
            postid,
            COUNT(*) AS comment_count
        FROM comments
        GROUP BY postid
    ),
    post_vote_counts AS (
        SELECT
            postid,
            COUNT(*) AS vote_count
        FROM votes
        GROUP BY postid
    ),
    owner_badge_counts AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    owner_reputations AS (
        SELECT
            id AS user_id,
            reputation
        FROM users
    ),
    tag_metrics AS (
        SELECT
            tp.tag_id,
            COUNT(DISTINCT tp.post_id) AS post_count,
            SUM(tp.score) AS total_post_score,
            AVG(tp.score) AS avg_post_score,
            SUM(tp.viewcount) AS total_viewcount
        FROM tag_posts tp
        GROUP BY tp.tag_id
    ),
    tag_comment_metrics AS (
        SELECT
            tp.tag_id,
            SUM(COALESCE(pcc.comment_count, 0)) AS total_comment_count
        FROM tag_posts tp
        LEFT JOIN post_comment_counts pcc
            ON tp.post_id = pcc.postid
        GROUP BY tp.tag_id
    ),
    tag_vote_metrics AS (
        SELECT
            tp.tag_id,
            SUM(COALESCE(pvc.vote_count, 0)) AS total_vote_count
        FROM tag_posts tp
        LEFT JOIN post_vote_counts pvc
            ON tp.post_id = pvc.postid
        GROUP BY tp.tag_id
    ),
    tag_owners AS (
        SELECT DISTINCT
            tp.tag_id,
            tp.owneruserid
        FROM tag_posts tp
    ),
    tag_owner_metrics AS (
        SELECT
            towner.tag_id,
            COUNT(*) AS distinct_owner_count,
            SUM(COALESCE(ur.reputation, 0)) AS total_owner_reputation,
            SUM(COALESCE(obc.badge_count, 0)) AS total_owner_badge_count
        FROM tag_owners towner
        LEFT JOIN owner_reputations ur
            ON towner.owneruserid = ur.user_id
        LEFT JOIN owner_badge_counts obc
            ON towner.owneruserid = obc.userid
        GROUP BY towner.tag_id
    )
SELECT
    tm.tag_id,
    tm.post_count,
    tm.total_post_score,
    tm.avg_post_score,
    tm.total_viewcount,
    tcm.total_comment_count,
    tvm.total_vote_count,
    tom.distinct_owner_count,
    tom.total_owner_reputation,
    tom.total_owner_badge_count
FROM tag_metrics tm
LEFT JOIN tag_comment_metrics tcm
    ON tm.tag_id = tcm.tag_id
LEFT JOIN tag_vote_metrics tvm
    ON tm.tag_id = tvm.tag_id
LEFT JOIN tag_owner_metrics tom
    ON tm.tag_id = tom.tag_id
ORDER BY tm.total_post_score DESC
LIMIT 100
