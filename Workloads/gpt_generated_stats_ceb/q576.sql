WITH owned_posts AS (
    SELECT p.owneruserid AS user_id,
           p.id AS post_id,
           p.score,
           p.viewcount,
           p.answercount,
           p.commentcount,
           p.favoritecount
    FROM posts p
),
post_links_counts AS (
    SELECT pl.postid AS post_id,
           COUNT(*) AS link_count_from
    FROM postlinks pl
    GROUP BY pl.postid
),
post_links_counts_rev AS (
    SELECT pl.relatedpostid AS post_id,
           COUNT(*) AS link_count_to
    FROM postlinks pl
    GROUP BY pl.relatedpostid
),
post_tags_counts AS (
    SELECT t.excerptpostid AS post_id,
           COUNT(*) AS tag_count
    FROM tags t
    GROUP BY t.excerptpostid
),
user_post_aggregates AS (
    SELECT op.user_id,
           COUNT(*) AS total_posts_owned,
           SUM(op.score) AS total_score,
           SUM(op.viewcount) AS total_views,
           SUM(op.answercount) AS total_answers,
           SUM(op.commentcount) AS total_comments,
           SUM(op.favoritecount) AS total_favorites,
           COALESCE(SUM(plc.link_count_from), 0) AS total_links_from,
           COALESCE(SUM(plc_rev.link_count_to), 0) AS total_links_to,
           COALESCE(SUM(ptc.tag_count), 0) AS total_tags
    FROM owned_posts op
    LEFT JOIN post_links_counts plc ON op.post_id = plc.post_id
    LEFT JOIN post_links_counts_rev plc_rev ON op.post_id = plc_rev.post_id
    LEFT JOIN post_tags_counts ptc ON op.post_id = ptc.post_id
    GROUP BY op.user_id
),
user_edit_aggregates AS (
    SELECT p.lasteditoruserid AS user_id,
           COUNT(*) AS total_posts_edited
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_history_aggregates AS (
    SELECT ph.userid AS user_id,
           COUNT(*) AS total_history_events,
           COUNT(DISTINCT ph.posthistorytypeid) AS distinct_history_types
    FROM posthistory ph
    GROUP BY ph.userid
),
posthistory_on_owned_posts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS total_history_events_on_owned_posts,
           COUNT(DISTINCT ph.userid) AS distinct_users_interacting_on_owned_posts
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.total_posts_owned, 0) AS total_posts_owned,
       COALESCE(ue.total_posts_edited, 0) AS total_posts_edited,
       COALESCE(up.total_score, 0) AS total_score,
       COALESCE(up.total_views, 0) AS total_views,
       COALESCE(up.total_answers, 0) AS total_answers,
       COALESCE(up.total_comments, 0) AS total_comments,
       COALESCE(up.total_favorites, 0) AS total_favorites,
       COALESCE(up.total_links_from, 0) AS total_links_from_owned_posts,
       COALESCE(up.total_links_to, 0) AS total_links_to_owned_posts,
       COALESCE(up.total_tags, 0) AS total_tags_in_owned_posts,
       COALESCE(uh.total_history_events, 0) AS total_history_events_by_user,
       COALESCE(uh.distinct_history_types, 0) AS distinct_history_types_by_user,
       COALESCE(phob.total_history_events_on_owned_posts, 0) AS total_history_events_on_owned_posts,
       COALESCE(phob.distinct_users_interacting_on_owned_posts, 0) AS distinct_users_interacting_on_owned_posts
FROM users u
LEFT JOIN user_post_aggregates up ON u.id = up.user_id
LEFT JOIN user_edit_aggregates ue ON u.id = ue.user_id
LEFT JOIN user_history_aggregates uh ON u.id = uh.user_id
LEFT JOIN posthistory_on_owned_posts phob ON u.id = phob.user_id
ORDER BY total_posts_owned DESC
LIMIT 100
