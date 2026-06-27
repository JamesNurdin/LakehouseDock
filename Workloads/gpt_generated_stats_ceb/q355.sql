WITH
    -- Aggregation of posts owned by each user
    posts_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_posts,
            SUM(p.score) AS total_post_score,
            AVG(p.score) AS avg_post_score,
            SUM(p.viewcount) AS total_views,
            SUM(p.answercount) AS total_answers,
            SUM(p.commentcount) AS total_comments_on_posts,
            SUM(p.favoritecount) AS total_favorites
        FROM
            posts p
        GROUP BY
            p.owneruserid
    ),
    -- Aggregation of comments made by each user
    comments_agg AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS total_comments_made,
            SUM(c.score) AS total_comment_score
        FROM
            comments c
        GROUP BY
            c.userid
    ),
    -- Aggregation of votes cast by each user
    votes_cast_agg AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS total_votes_cast,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM
            votes v
        GROUP BY
            v.userid
    ),
    -- Aggregation of votes received on a user's posts
    votes_received_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_votes_received,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
        FROM
            votes v
            JOIN posts p ON v.postid = p.id
        GROUP BY
            p.owneruserid
    ),
    -- Aggregation of badges earned by each user
    badges_agg AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS total_badges
        FROM
            badges b
        GROUP BY
            b.userid
    ),
    -- Aggregation of edits performed by each user (as last editor of a post)
    edits_agg AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS total_edits
        FROM
            posts p
        WHERE
            p.lasteditoruserid IS NOT NULL
        GROUP BY
            p.lasteditoruserid
    ),
    -- Aggregation of post‑history entries created by each user
    posthistory_agg AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS total_posthistory_entries
        FROM
            posthistory ph
        GROUP BY
            ph.userid
    ),
    -- Aggregation of tag usage on a user's posts
    tags_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS distinct_tags_used,
            SUM(t.count) AS total_tag_usage
        FROM
            posts p
            JOIN tags t ON t.excerptpostid = p.id
        GROUP BY
            p.owneruserid
    ),
    -- Aggregation of post‑link count on a user's posts
    postlinks_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_postlinks
        FROM
            postlinks pl
            JOIN posts p ON pl.postid = p.id
        GROUP BY
            p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(pa.total_posts, 0) AS total_posts,
    COALESCE(pa.total_post_score, 0) AS total_post_score,
    COALESCE(pa.avg_post_score, 0) AS avg_post_score,
    COALESCE(pa.total_views, 0) AS total_views,
    COALESCE(pa.total_answers, 0) AS total_answers,
    COALESCE(pa.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(pa.total_favorites, 0) AS total_favorites,
    COALESCE(ca.total_comments_made, 0) AS total_comments_made,
    COALESCE(ca.total_comment_score, 0) AS total_comment_score,
    COALESCE(vca.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vca.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vca.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vra.total_votes_received, 0) AS total_votes_received,
    COALESCE(vra.upvotes_received, 0) AS upvotes_received,
    COALESCE(vra.downvotes_received, 0) AS downvotes_received,
    COALESCE(ba.total_badges, 0) AS total_badges,
    COALESCE(ea.total_edits, 0) AS total_edits,
    COALESCE(pha.total_posthistory_entries, 0) AS total_posthistory_entries,
    COALESCE(ta.distinct_tags_used, 0) AS distinct_tags_used,
    COALESCE(ta.total_tag_usage, 0) AS total_tag_usage,
    COALESCE(pla.total_postlinks, 0) AS total_postlinks
FROM
    users u
    LEFT JOIN posts_agg pa ON pa.user_id = u.id
    LEFT JOIN comments_agg ca ON ca.user_id = u.id
    LEFT JOIN votes_cast_agg vca ON vca.user_id = u.id
    LEFT JOIN votes_received_agg vra ON vra.user_id = u.id
    LEFT JOIN badges_agg ba ON ba.user_id = u.id
    LEFT JOIN edits_agg ea ON ea.user_id = u.id
    LEFT JOIN posthistory_agg pha ON pha.user_id = u.id
    LEFT JOIN tags_agg ta ON ta.user_id = u.id
    LEFT JOIN postlinks_agg pla ON pla.user_id = u.id
ORDER BY
    total_posts DESC,
    total_votes_received DESC
LIMIT 100
