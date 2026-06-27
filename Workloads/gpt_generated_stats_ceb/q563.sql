WITH vote_stats AS (
   SELECT
       v.postid,
       COUNT(*) AS vote_count,
       COUNT(DISTINCT v.userid) AS distinct_voter_count,
       SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
       SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
       AVG(u.reputation) AS avg_voter_reputation
   FROM votes v
   JOIN users u ON v.userid = u.id
   GROUP BY v.postid
),
ph_stats AS (
   SELECT
       ph.posthistorytypeid AS postid,
       COUNT(*) AS ph_count,
       COUNT(DISTINCT ph.userid) AS distinct_editor_count,
       AVG(u.reputation) AS avg_editor_reputation
   FROM posthistory ph
   JOIN users u ON ph.userid = u.id
   GROUP BY ph.posthistorytypeid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    owner.id AS owner_user_id,
    owner.reputation AS owner_reputation,
    last_editor.id AS last_editor_user_id,
    last_editor.reputation AS last_editor_reputation,
    COALESCE(vs.vote_count, 0) AS vote_count,
    COALESCE(vs.distinct_voter_count, 0) AS distinct_voter_count,
    COALESCE(vs.upvote_count, 0) AS upvote_count,
    COALESCE(vs.downvote_count, 0) AS downvote_count,
    COALESCE(vs.avg_voter_reputation, 0) AS avg_voter_reputation,
    COALESCE(ps.ph_count, 0) AS posthistory_event_count,
    COALESCE(ps.distinct_editor_count, 0) AS distinct_editor_count,
    COALESCE(ps.avg_editor_reputation, 0) AS avg_editor_reputation
FROM posts p
LEFT JOIN users owner ON p.owneruserid = owner.id
LEFT JOIN users last_editor ON p.lasteditoruserid = last_editor.id
LEFT JOIN vote_stats vs ON vs.postid = p.id
LEFT JOIN ph_stats ps ON ps.postid = p.id
ORDER BY p.creationdate DESC
LIMIT 100
