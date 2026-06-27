WITH
    tag_posts AS (
        SELECT
            t.id AS tag_id,
            t.count AS tag_use_count,
            p.id AS post_id,
            p.score,
            p.owneruserid
        FROM tags t
        JOIN posts p
            ON t.excerptpostid = p.id
    ),
    owner_rep AS (
        SELECT
            u.id AS user_id,
            u.reputation
        FROM users u
    ),
    votes_agg AS (
        SELECT
            v.postid,
            COUNT(*) AS vote_cnt,
            SUM(v.bountyamount) AS total_bounty
        FROM votes v
        GROUP BY v.postid
    ),
    posthistory_agg AS (
        SELECT
            ph.posthistorytypeid AS post_id,
            COUNT(*) AS edit_cnt
        FROM posthistory ph
        GROUP BY ph.posthistorytypeid
    )
SELECT
    tp.tag_id,
    tp.tag_use_count,
    COUNT(DISTINCT tp.post_id) AS excerpt_post_cnt,
    SUM(tp.score) AS total_score,
    AVG(owner.reputation) AS avg_owner_reputation,
    COALESCE(SUM(v.vote_cnt), 0) AS total_votes,
    COALESCE(SUM(v.total_bounty), 0) AS total_bounty_amount,
    COALESCE(SUM(ph.edit_cnt), 0) AS total_edits
FROM tag_posts tp
LEFT JOIN owner_rep owner
    ON tp.owneruserid = owner.user_id
LEFT JOIN votes_agg v
    ON tp.post_id = v.postid
LEFT JOIN posthistory_agg ph
    ON tp.post_id = ph.post_id
GROUP BY tp.tag_id, tp.tag_use_count
ORDER BY total_score DESC
LIMIT 20
