/*
  Analytical query: user‑centric activity summary.
  For each user we compute counts and aggregates of their posts, comments, votes cast,
  post‑history events, and votes received on their posts.
*/
SELECT
    u.id                                            AS user_id,
    u.reputation,
    COUNT(DISTINCT p.id)                            AS post_count,
    COALESCE(SUM(p.score), 0)                       AS total_post_score,
    COALESCE(SUM(p.viewcount), 0)                   AS total_post_views,
    COALESCE(SUM(p.answercount), 0)                 AS total_answer_count,
    COALESCE(SUM(p.commentcount), 0)                AS total_comment_count_on_posts,
    COALESCE(COUNT(DISTINCT c.id), 0)               AS comment_made_count,
    COALESCE(SUM(c.score), 0)                       AS total_comment_score,
    COALESCE(COUNT(DISTINCT v.id), 0)               AS vote_cast_count,
    COALESCE(SUM(CASE WHEN v.votetypeid = 8 THEN v.bountyamount ELSE 0 END), 0) AS total_bounty_given,
    COALESCE(COUNT(DISTINCT ph.id), 0)              AS post_history_event_count,
    COALESCE(SUM(vr.vote_received_count), 0)        AS total_votes_received,
    COALESCE(SUM(vr.vote_received_score), 0)        AS total_vote_score_received
FROM users u
LEFT JOIN posts p
    ON p.owneruserid = u.id                     -- posts owned by the user
LEFT JOIN comments c
    ON c.userid = u.id                          -- comments authored by the user
LEFT JOIN votes v
    ON v.userid = u.id                          -- votes cast by the user
LEFT JOIN posthistory ph
    ON ph.userid = u.id                         -- post‑history events performed by the user
LEFT JOIN (
    SELECT
        p.owneruserid                              AS owner_user_id,
        COUNT(v.id)                                 AS vote_received_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1
                           WHEN v.votetypeid = 3 THEN -1
                           ELSE 0 END), 0)      AS vote_received_score
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id                        -- votes received on a post
    GROUP BY p.owneruserid
) vr
    ON vr.owner_user_id = u.id
GROUP BY u.id, u.reputation
ORDER BY total_post_score DESC
LIMIT 20
