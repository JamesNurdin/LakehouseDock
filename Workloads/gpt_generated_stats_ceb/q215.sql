-- Analytical query: tag‑level activity summary based on the exemplar post for each tag
WITH comment_counts AS (
    SELECT postid, COUNT(*) AS comment_cnt
    FROM comments
    GROUP BY postid
),
vote_counts AS (
    SELECT postid, COUNT(*) AS vote_cnt
    FROM votes
    GROUP BY postid
),
out_link_counts AS (
    SELECT postid, COUNT(*) AS out_link_cnt
    FROM postlinks
    GROUP BY postid
),
in_link_counts AS (
    SELECT relatedpostid, COUNT(*) AS in_link_cnt
    FROM postlinks
    GROUP BY relatedpostid
),
owner_badge_counts AS (
    SELECT userid, COUNT(*) AS badge_cnt
    FROM badges
    GROUP BY userid
),
post_aggregates AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.owneruserid,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.lasteditoruserid,
        COALESCE(cc.comment_cnt, 0) AS comment_cnt,
        COALESCE(vc.vote_cnt, 0) AS vote_cnt,
        COALESCE(olc.out_link_cnt, 0) AS out_link_cnt,
        COALESCE(ilc.in_link_cnt, 0) AS in_link_cnt
    FROM posts p
    LEFT JOIN comment_counts cc ON cc.postid = p.id
    LEFT JOIN vote_counts vc ON vc.postid = p.id
    LEFT JOIN out_link_counts olc ON olc.postid = p.id
    LEFT JOIN in_link_counts ilc ON ilc.relatedpostid = p.id
)
SELECT
    t.id AS tag_id,
    t.excerptpostid AS exemplar_post_id,
    COUNT(DISTINCT pa.post_id) AS num_posts,
    SUM(pa.viewcount) AS total_views,
    AVG(pa.score) AS avg_post_score,
    SUM(pa.comment_cnt) AS total_comments_on_posts,
    SUM(pa.vote_cnt) AS total_votes_on_posts,
    SUM(pa.out_link_cnt + pa.in_link_cnt) AS total_links_on_posts,
    COUNT(DISTINCT u.id) AS num_distinct_owners,
    SUM(COALESCE(obc.badge_cnt, 0)) AS total_owner_badges
FROM tags t
LEFT JOIN posts p ON p.id = t.excerptpostid                      -- allowed join rule
LEFT JOIN post_aggregates pa ON pa.post_id = p.id               -- derived join on post id
LEFT JOIN users u ON u.id = p.owneruserid                       -- allowed join rule
LEFT JOIN owner_badge_counts obc ON obc.userid = u.id           -- allowed join rule
GROUP BY t.id, t.excerptpostid
ORDER BY total_views DESC
LIMIT 20
