WITH
    user_base AS (
        SELECT id,
               reputation,
               creationdate,
               views,
               upvotes,
               downvotes
        FROM users
    ),
    post_metrics AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT p.id) AS post_count,
               COALESCE(SUM(p.score), 0) AS total_post_score,
               COALESCE(AVG(p.score), 0) AS avg_post_score,
               COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
               COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount,
               COALESCE(SUM(p.answercount), 0) AS total_answercount,
               COALESCE(SUM(p.commentcount), 0) AS total_commentcount
        FROM posts p
        GROUP BY p.owneruserid
    ),
    comment_metrics AS (
        SELECT c.userid,
               COUNT(DISTINCT c.id) AS comment_count,
               COALESCE(SUM(c.score), 0) AS total_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    vote_metrics AS (
        SELECT v.userid,
               COUNT(DISTINCT v.id) AS vote_count,
               COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount
        FROM votes v
        GROUP BY v.userid
    ),
    badge_metrics AS (
        SELECT b.userid,
               COUNT(DISTINCT b.id) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    tag_metrics AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    outgoing_link_metrics AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT pl.id) AS outgoing_link_count
        FROM posts p
        JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    incoming_link_metrics AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT pl.id) AS incoming_link_count
        FROM posts p
        JOIN postlinks pl ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    edit_metrics AS (
        SELECT ph.userid,
               COUNT(DISTINCT ph.id) AS edit_count
        FROM posthistory ph
        GROUP BY ph.userid
    )
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate AS user_creationdate,
       u.views AS user_views,
       u.upvotes,
       u.downvotes,
       COALESCE(pm.post_count, 0) AS post_count,
       COALESCE(pm.total_post_score, 0) AS total_post_score,
       COALESCE(pm.avg_post_score, 0) AS avg_post_score,
       COALESCE(pm.total_viewcount, 0) AS total_viewcount,
       COALESCE(pm.total_favoritecount, 0) AS total_favoritecount,
       COALESCE(pm.total_answercount, 0) AS total_answercount,
       COALESCE(pm.total_commentcount, 0) AS total_commentcount,
       COALESCE(cm.comment_count, 0) AS comment_count,
       COALESCE(cm.total_comment_score, 0) AS total_comment_score,
       COALESCE(vm.vote_count, 0) AS vote_count,
       COALESCE(vm.total_bounty_amount, 0) AS total_bounty_amount,
       COALESCE(bm.badge_count, 0) AS badge_count,
       COALESCE(tm.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(olm.outgoing_link_count, 0) AS outgoing_link_count,
       COALESCE(ilm.incoming_link_count, 0) AS incoming_link_count,
       COALESCE(em.edit_count, 0) AS edit_count
FROM user_base u
LEFT JOIN post_metrics pm ON pm.userid = u.id
LEFT JOIN comment_metrics cm ON cm.userid = u.id
LEFT JOIN vote_metrics vm ON vm.userid = u.id
LEFT JOIN badge_metrics bm ON bm.userid = u.id
LEFT JOIN tag_metrics tm ON tm.userid = u.id
LEFT JOIN outgoing_link_metrics olm ON olm.userid = u.id
LEFT JOIN incoming_link_metrics ilm ON ilm.userid = u.id
LEFT JOIN edit_metrics em ON em.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
