WITH vote_agg AS (
    SELECT
        postid AS post_id,
        COUNT(*) AS vote_count,
        COALESCE(SUM(bountyamount), 0) AS total_bounty
    FROM votes
    GROUP BY postid
),
link_union AS (
    SELECT postid AS post_id, relatedpostid AS linked_post_id FROM postlinks
    UNION ALL
    SELECT relatedpostid AS post_id, postid AS linked_post_id FROM postlinks
),
link_agg AS (
    SELECT
        post_id,
        COUNT(DISTINCT linked_post_id) AS total_linked_posts
    FROM link_union
    GROUP BY post_id
),
post_metrics AS (
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
        COALESCE(v.vote_count, 0) AS vote_count,
        COALESCE(v.total_bounty, 0) AS total_bounty,
        COALESCE(l.total_linked_posts, 0) AS total_linked_posts
    FROM posts p
    LEFT JOIN vote_agg v ON v.post_id = p.id
    LEFT JOIN link_agg l ON l.post_id = p.id
),
ranked_posts AS (
    SELECT
        post_id,
        posttypeid,
        creationdate,
        score,
        viewcount,
        owneruserid,
        answercount,
        commentcount,
        favoritecount,
        lasteditoruserid,
        vote_count,
        total_bounty,
        total_linked_posts,
        ROW_NUMBER() OVER (PARTITION BY posttypeid ORDER BY vote_count DESC) AS rank_in_type
    FROM post_metrics
)
SELECT
    post_id,
    posttypeid,
    creationdate,
    score,
    viewcount,
    owneruserid,
    answercount,
    commentcount,
    favoritecount,
    lasteditoruserid,
    vote_count,
    total_bounty,
    total_linked_posts,
    rank_in_type
FROM ranked_posts
WHERE rank_in_type <= 5
ORDER BY posttypeid, rank_in_type
