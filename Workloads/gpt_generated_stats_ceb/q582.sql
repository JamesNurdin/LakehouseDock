WITH comment_stats AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        COUNT(DISTINCT userid) AS distinct_commenters
    FROM comments
    GROUP BY postid
),
vote_stats AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cnt,
        SUM(COALESCE(bountyamount, 0)) AS total_bounty
    FROM votes
    GROUP BY postid
),
outgoing_links AS (
    SELECT
        postid,
        COUNT(*) AS outgoing_links
    FROM postlinks
    GROUP BY postid
),
incoming_links AS (
    SELECT
        relatedpostid AS postid,
        COUNT(*) AS incoming_links
    FROM postlinks
    GROUP BY relatedpostid
),
link_stats AS (
    SELECT
        p.id AS postid,
        COALESCE(o.outgoing_links, 0) AS outgoing_links,
        COALESCE(i.incoming_links, 0) AS incoming_links
    FROM posts p
    LEFT JOIN outgoing_links o ON o.postid = p.id
    LEFT JOIN incoming_links i ON i.postid = p.id
),
tag_stats AS (
    SELECT
        excerptpostid AS postid,
        COUNT(*) AS tag_cnt
    FROM tags
    GROUP BY excerptpostid
),
owner_rep AS (
    SELECT
        id AS userid,
        reputation
    FROM users
),
post_with_stats AS (
    SELECT
        p.id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.owneruserid,
        p.lasteditoruserid,
        COALESCE(cs.comment_cnt, 0) AS comment_cnt,
        COALESCE(cs.distinct_commenters, 0) AS distinct_commenters,
        COALESCE(vs.vote_cnt, 0) AS vote_cnt,
        COALESCE(vs.upvote_cnt, 0) AS upvote_cnt,
        COALESCE(vs.downvote_cnt, 0) AS downvote_cnt,
        COALESCE(vs.total_bounty, 0) AS total_bounty,
        COALESCE(ls.outgoing_links, 0) AS outgoing_links,
        COALESCE(ls.incoming_links, 0) AS incoming_links,
        COALESCE(ts.tag_cnt, 0) AS tag_cnt,
        orp.reputation AS owner_reputation,
        lepr.reputation AS last_editor_reputation
    FROM posts p
    LEFT JOIN comment_stats cs ON cs.postid = p.id
    LEFT JOIN vote_stats vs ON vs.postid = p.id
    LEFT JOIN link_stats ls ON ls.postid = p.id
    LEFT JOIN tag_stats ts ON ts.postid = p.id
    LEFT JOIN owner_rep orp ON orp.userid = p.owneruserid
    LEFT JOIN owner_rep lepr ON lepr.userid = p.lasteditoruserid
)
SELECT
    posttypeid,
    COUNT(*) AS total_posts,
    AVG(score) AS avg_score,
    AVG(viewcount) AS avg_views,
    AVG(answercount) AS avg_answers,
    AVG(commentcount) AS avg_comments,
    AVG(comment_cnt) AS avg_comment_rows,
    AVG(distinct_commenters) AS avg_distinct_commenters,
    AVG(vote_cnt) AS avg_votes,
    AVG(upvote_cnt) AS avg_upvotes,
    AVG(downvote_cnt) AS avg_downvotes,
    AVG(total_bounty) AS avg_bounty,
    AVG(outgoing_links) AS avg_outgoing_links,
    AVG(incoming_links) AS avg_incoming_links,
    AVG(tag_cnt) AS avg_tags_per_post,
    AVG(owner_reputation) AS avg_owner_rep,
    AVG(last_editor_reputation) AS avg_last_editor_rep,
    CASE WHEN AVG(downvote_cnt) = 0 THEN NULL
         ELSE AVG(upvote_cnt) / AVG(downvote_cnt) END AS avg_up_to_down_ratio
FROM post_with_stats
GROUP BY posttypeid
ORDER BY total_posts DESC
