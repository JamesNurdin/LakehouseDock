WITH
    post_votes AS (
        SELECT
            votes.postid AS post_id,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votes.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
        FROM votes
        GROUP BY votes.postid
    ),
    post_history AS (
        SELECT
            posthistory.posthistorytypeid AS post_id,
            COUNT(*) AS history_event_count
        FROM posthistory
        GROUP BY posthistory.posthistorytypeid
    ),
    post_links_src AS (
        SELECT
            postlinks.postid AS post_id,
            COUNT(*) AS link_as_source_count
        FROM postlinks
        GROUP BY postlinks.postid
    ),
    post_links_tgt AS (
        SELECT
            postlinks.relatedpostid AS post_id,
            COUNT(*) AS link_as_target_count
        FROM postlinks
        GROUP BY postlinks.relatedpostid
    ),
    post_links_agg AS (
        SELECT
            COALESCE(src.post_id, tgt.post_id) AS post_id,
            COALESCE(src.link_as_source_count, 0) + COALESCE(tgt.link_as_target_count, 0) AS total_link_count
        FROM post_links_src src
        FULL OUTER JOIN post_links_tgt tgt
            ON src.post_id = tgt.post_id
    )
SELECT
    tags.id AS tag_id,
    tags.count AS tag_post_count,
    COUNT(DISTINCT posts.id) AS associated_posts,
    AVG(posts.score) AS avg_score,
    SUM(posts.viewcount) AS total_views,
    COALESCE(SUM(post_votes.vote_count), 0) AS total_votes,
    COALESCE(SUM(post_history.history_event_count), 0) AS total_history_events,
    COALESCE(SUM(post_links_agg.total_link_count), 0) AS total_links,
    AVG(owner_user.reputation) AS avg_owner_reputation,
    AVG(editor_user.reputation) AS avg_last_editor_reputation
FROM tags
JOIN posts
    ON tags.excerptpostid = posts.id
LEFT JOIN post_votes
    ON post_votes.post_id = posts.id
LEFT JOIN post_history
    ON post_history.post_id = posts.id
LEFT JOIN post_links_agg
    ON post_links_agg.post_id = posts.id
LEFT JOIN users AS owner_user
    ON posts.owneruserid = owner_user.id
LEFT JOIN users AS editor_user
    ON posts.lasteditoruserid = editor_user.id
GROUP BY tags.id, tags.count
ORDER BY total_votes DESC
LIMIT 10
