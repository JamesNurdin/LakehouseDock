WITH comment_stats AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum,
        COUNT(DISTINCT c.userid) AS distinct_comment_user_count
    FROM comments c
    GROUP BY c.postid
),
vote_stats AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS close_vote_count,
        COUNT(DISTINCT v.userid) AS distinct_voter_user_count
    FROM votes v
    GROUP BY v.postid
),
outgoing_link_stats AS (
    SELECT
        pl.postid AS post_id,
        COUNT(*) AS outgoing_link_count,
        COUNT(DISTINCT pl.relatedpostid) AS distinct_related_post_count,
        SUM(CASE WHEN pl.linktypeid = 1 THEN 1 ELSE 0 END) AS duplicate_link_count
    FROM postlinks pl
    GROUP BY pl.postid
),
incoming_link_stats AS (
    SELECT
        pl.relatedpostid AS post_id,
        COUNT(*) AS incoming_link_count,
        COUNT(DISTINCT pl.postid) AS distinct_incoming_post_count
    FROM postlinks pl
    GROUP BY pl.relatedpostid
),
edit_stats AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS edit_count,
        COUNT(DISTINCT ph.userid) AS distinct_editor_user_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    p.owneruserid,
    owner.reputation AS owner_reputation,
    p.lasteditoruserid,
    editor.reputation AS last_editor_reputation,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(cs.distinct_comment_user_count, 0) AS distinct_comment_user_count,
    COALESCE(vs.vote_count, 0) AS vote_count,
    COALESCE(vs.upvote_count, 0) AS upvote_count,
    COALESCE(vs.downvote_count, 0) AS downvote_count,
    COALESCE(vs.close_vote_count, 0) AS close_vote_count,
    COALESCE(vs.distinct_voter_user_count, 0) AS distinct_voter_user_count,
    COALESCE(ols.outgoing_link_count, 0) AS outgoing_link_count,
    COALESCE(ols.distinct_related_post_count, 0) AS distinct_related_post_count,
    COALESCE(ols.duplicate_link_count, 0) AS duplicate_link_count,
    COALESCE(ils.incoming_link_count, 0) AS incoming_link_count,
    COALESCE(ils.distinct_incoming_post_count, 0) AS distinct_incoming_post_count,
    COALESCE(es.edit_count, 0) AS edit_count,
    COALESCE(es.distinct_editor_user_count, 0) AS distinct_editor_user_count
FROM posts p
LEFT JOIN comment_stats cs ON cs.post_id = p.id
LEFT JOIN vote_stats vs ON vs.post_id = p.id
LEFT JOIN outgoing_link_stats ols ON ols.post_id = p.id
LEFT JOIN incoming_link_stats ils ON ils.post_id = p.id
LEFT JOIN edit_stats es ON es.post_id = p.id
LEFT JOIN users owner ON owner.id = p.owneruserid
LEFT JOIN users editor ON editor.id = p.lasteditoruserid
ORDER BY p.creationdate DESC
LIMIT 100
