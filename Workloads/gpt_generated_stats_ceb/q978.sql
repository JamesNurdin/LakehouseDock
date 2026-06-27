WITH post_votes AS (
    SELECT v.postid,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes
    FROM votes v
    GROUP BY v.postid
),
post_comments AS (
    SELECT c.postid,
           COUNT(*) AS comment_count,
           SUM(c.score) AS comment_score
    FROM comments c
    GROUP BY c.postid
),
post_history AS (
    SELECT ph.posthistorytypeid AS postid,
           COUNT(*) AS history_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
),
post_links AS (
    SELECT pl.postid,
           COUNT(*) AS link_count
    FROM postlinks pl
    GROUP BY pl.postid
),
user_badges AS (
    SELECT b.userid,
           COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
owner_info AS (
    SELECT u.id,
           u.reputation
    FROM users u
)
SELECT
    t.id AS tag_id,
    t.count AS tag_usage,
    p.id AS post_id,
    p.score AS post_score,
    p.viewcount,
    p.favoritecount,
    p.answercount,
    p.commentcount,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.up_votes, 0) AS up_votes,
    COALESCE(v.down_votes, 0) AS down_votes,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.comment_score, 0) AS comment_score,
    COALESCE(h.history_count, 0) AS history_count,
    COALESCE(l.link_count, 0) AS link_count,
    COALESCE(ob.badge_count, 0) AS owner_badge_count,
    COALESCE(eb.badge_count, 0) AS editor_badge_count,
    COALESCE(oi.reputation, 0) AS owner_reputation,
    COALESCE(ei.reputation, 0) AS editor_reputation,
    (COALESCE(v.vote_count, 0) * 1.0
     + COALESCE(c.comment_score, 0) * 0.5
     + COALESCE(oi.reputation, 0) * 0.01
     + COALESCE(ob.badge_count, 0) * 2.0) AS weighted_score,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(v.vote_count, 0) * 1.0
                                 + COALESCE(c.comment_score, 0) * 0.5
                                 + COALESCE(oi.reputation, 0) * 0.01
                                 + COALESCE(ob.badge_count, 0) * 2.0) DESC) AS tag_rank
FROM tags t
JOIN posts p ON t.excerptpostid = p.id
LEFT JOIN post_votes v ON p.id = v.postid
LEFT JOIN post_comments c ON p.id = c.postid
LEFT JOIN post_history h ON p.id = h.postid
LEFT JOIN post_links l ON p.id = l.postid
LEFT JOIN users oi ON p.owneruserid = oi.id
LEFT JOIN users ei ON p.lasteditoruserid = ei.id
LEFT JOIN user_badges ob ON oi.id = ob.userid
LEFT JOIN user_badges eb ON ei.id = eb.userid
ORDER BY weighted_score DESC
LIMIT 10
