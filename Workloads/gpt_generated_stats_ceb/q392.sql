WITH post_comment_agg AS (
    SELECT
        c.postid,
        count(*) AS comment_count,
        sum(c.score) AS comment_score_sum
    FROM comments c
    GROUP BY c.postid
),
post_vote_agg AS (
    SELECT
        v.postid,
        count(*) AS vote_count,
        sum(v.bountyamount) AS vote_bounty_sum
    FROM votes v
    GROUP BY v.postid
),
post_history_agg AS (
    SELECT
        ph.posthistorytypeid AS postid,
        count(*) AS history_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
),
post_links_out AS (
    SELECT
        pl.postid,
        count(*) AS outgoing_link_count
    FROM postlinks pl
    GROUP BY pl.postid
),
post_links_in AS (
    SELECT
        pl.relatedpostid AS postid,
        count(*) AS incoming_link_count
    FROM postlinks pl
    GROUP BY pl.relatedpostid
),
post_tag_agg AS (
    SELECT
        t.excerptpostid AS postid,
        count(*) AS tag_count
    FROM tags t
    GROUP BY t.excerptpostid
)
SELECT
    p.owneruserid AS owner_user_id,
    u.reputation AS owner_reputation,
    u.creationdate AS owner_creationdate,
    count(p.id) AS post_count,
    sum(p.score) AS total_post_score,
    avg(p.score) AS avg_post_score,
    sum(coalesce(cagg.comment_count, 0)) AS total_comment_count,
    sum(coalesce(cagg.comment_score_sum, 0)) AS total_comment_score,
    sum(coalesce(vagg.vote_count, 0)) AS total_vote_count,
    sum(coalesce(vagg.vote_bounty_sum, 0)) AS total_vote_bounty,
    sum(coalesce(hagg.history_count, 0)) AS total_history_count,
    sum(coalesce(loagg.outgoing_link_count, 0)) AS total_outgoing_link_count,
    sum(coalesce(liagg.incoming_link_count, 0)) AS total_incoming_link_count,
    sum(coalesce(tagagg.tag_count, 0)) AS total_tag_count
FROM posts p
LEFT JOIN users u
    ON p.owneruserid = u.id
LEFT JOIN post_comment_agg cagg
    ON cagg.postid = p.id
LEFT JOIN post_vote_agg vagg
    ON vagg.postid = p.id
LEFT JOIN post_history_agg hagg
    ON hagg.postid = p.id
LEFT JOIN post_links_out loagg
    ON loagg.postid = p.id
LEFT JOIN post_links_in liagg
    ON liagg.postid = p.id
LEFT JOIN post_tag_agg tagagg
    ON tagagg.postid = p.id
GROUP BY p.owneruserid, u.reputation, u.creationdate
ORDER BY total_post_score DESC
LIMIT 20
