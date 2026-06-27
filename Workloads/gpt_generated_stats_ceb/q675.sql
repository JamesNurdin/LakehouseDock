WITH
    user_base AS (
        SELECT id AS user_id, reputation
        FROM users
    ),
    post_agg AS (
        SELECT owneruserid AS user_id,
               COUNT(*) AS post_cnt,
               COALESCE(SUM(score), 0) AS post_score_sum
        FROM posts
        GROUP BY owneruserid
    ),
    comment_agg AS (
        SELECT userid AS user_id,
               COUNT(*) AS comment_cnt,
               COALESCE(SUM(score), 0) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    vote_agg AS (
        SELECT userid AS user_id,
               COUNT(*) AS vote_cnt,
               COALESCE(SUM(bountyamount), 0) AS vote_bounty_sum
        FROM votes
        GROUP BY userid
    ),
    badge_agg AS (
        SELECT userid AS user_id,
               COUNT(*) AS badge_cnt
        FROM badges
        GROUP BY userid
    ),
    edit_agg AS (
        SELECT lasteditoruserid AS user_id,
               COUNT(*) AS edit_cnt
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    posthistory_agg AS (
        SELECT userid AS user_id,
               COUNT(*) AS posthistory_cnt
        FROM posthistory
        GROUP BY userid
    ),
    tag_agg AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS tag_cnt,
               COALESCE(SUM(t.count), 0) AS tag_sum
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_out_agg AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS postlinks_out_cnt
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_in_agg AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS postlinks_in_cnt
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(pa.post_cnt, 0) AS post_cnt,
    COALESCE(pa.post_score_sum, 0) AS post_score_sum,
    COALESCE(ca.comment_cnt, 0) AS comment_cnt,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(va.vote_cnt, 0) AS vote_cnt,
    COALESCE(va.vote_bounty_sum, 0) AS vote_bounty_sum,
    COALESCE(ba.badge_cnt, 0) AS badge_cnt,
    COALESCE(ea.edit_cnt, 0) AS edit_cnt,
    COALESCE(pha.posthistory_cnt, 0) AS posthistory_cnt,
    COALESCE(ta.tag_cnt, 0) AS tag_cnt,
    COALESCE(ta.tag_sum, 0) AS tag_sum,
    COALESCE(plo.postlinks_out_cnt, 0) AS postlinks_out_cnt,
    COALESCE(pli.postlinks_in_cnt, 0) AS postlinks_in_cnt
FROM user_base ub
LEFT JOIN post_agg pa ON ub.user_id = pa.user_id
LEFT JOIN comment_agg ca ON ub.user_id = ca.user_id
LEFT JOIN vote_agg va ON ub.user_id = va.user_id
LEFT JOIN badge_agg ba ON ub.user_id = ba.user_id
LEFT JOIN edit_agg ea ON ub.user_id = ea.user_id
LEFT JOIN posthistory_agg pha ON ub.user_id = pha.user_id
LEFT JOIN tag_agg ta ON ub.user_id = ta.user_id
LEFT JOIN postlinks_out_agg plo ON ub.user_id = plo.user_id
LEFT JOIN postlinks_in_agg pli ON ub.user_id = pli.user_id
ORDER BY ub.reputation DESC, ub.user_id ASC
LIMIT 100
