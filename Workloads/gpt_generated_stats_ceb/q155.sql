WITH
    post_base AS (
        SELECT
            p.id,
            p.posttypeid,
            p.creationdate,
            p.score,
            p.viewcount,
            p.owneruserid,
            p.lasteditoruserid,
            p.answercount,
            p.commentcount,
            p.favoritecount
        FROM posts p
    ),
    comment_agg AS (
        SELECT
            c.postid,
            COUNT(*) AS comment_count,
            COALESCE(SUM(c.score), 0) AS comment_score_sum
        FROM comments c
        GROUP BY c.postid
    ),
    vote_agg AS (
        SELECT
            v.postid,
            COUNT(*) AS vote_count,
            COUNT(DISTINCT v.userid) AS distinct_voter_count,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
        FROM votes v
        GROUP BY v.postid
    ),
    posthistory_agg AS (
        SELECT
            ph.posthistorytypeid AS postid,
            COUNT(*) AS edit_count,
            COUNT(DISTINCT ph.userid) AS distinct_editor_count
        FROM posthistory ph
        GROUP BY ph.posthistorytypeid
    ),
    postlinks_out_agg AS (
        SELECT
            pl.postid,
            COUNT(*) AS outgoing_link_count
        FROM postlinks pl
        GROUP BY pl.postid
    ),
    postlinks_in_agg AS (
        SELECT
            pl.relatedpostid AS postid,
            COUNT(*) AS incoming_link_count
        FROM postlinks pl
        GROUP BY pl.relatedpostid
    ),
    tags_agg AS (
        SELECT
            t.excerptpostid AS postid,
            COUNT(*) AS tag_count
        FROM tags t
        GROUP BY t.excerptpostid
    )
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.owneruserid AS owner_user_id,
    o.reputation AS owner_reputation,
    p.lasteditoruserid AS last_editor_user_id,
    le.reputation AS last_editor_reputation,
    p.answercount,
    p.commentcount AS post_comment_count,
    p.favoritecount,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(va.vote_count, 0) AS vote_count,
    COALESCE(va.distinct_voter_count, 0) AS distinct_voter_count,
    COALESCE(va.upvote_count, 0) AS upvote_count,
    COALESCE(va.downvote_count, 0) AS downvote_count,
    COALESCE(pha.edit_count, 0) AS edit_count,
    COALESCE(pha.distinct_editor_count, 0) AS distinct_editor_count,
    COALESCE(pl_out.outgoing_link_count, 0) AS outgoing_link_count,
    COALESCE(pl_in.incoming_link_count, 0) AS incoming_link_count,
    COALESCE(tg.tag_count, 0) AS tag_count
FROM post_base p
LEFT JOIN users o ON p.owneruserid = o.id
LEFT JOIN users le ON p.lasteditoruserid = le.id
LEFT JOIN comment_agg ca ON ca.postid = p.id
LEFT JOIN vote_agg va ON va.postid = p.id
LEFT JOIN posthistory_agg pha ON pha.postid = p.id
LEFT JOIN postlinks_out_agg pl_out ON pl_out.postid = p.id
LEFT JOIN postlinks_in_agg pl_in ON pl_in.postid = p.id
LEFT JOIN tags_agg tg ON tg.postid = p.id
ORDER BY p.creationdate DESC
LIMIT 100
