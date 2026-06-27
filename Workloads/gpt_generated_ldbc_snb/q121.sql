/*
  Top 10 forums by total likes on their posts, showing basic forum stats,
  the most common tag used in the forum, and the moderator's name.
*/
WITH forum_info AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.moderator_person_id
    FROM forum f
),
moderator_info AS (
    SELECT
        p.id AS person_id,
        CONCAT(p.first_name, ' ', p.last_name) AS moderator_name
    FROM person p
),
forum_posts AS (
    SELECT
        f.id AS forum_id,
        p.id AS post_id,
        p.length AS post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
),
post_likes AS (
    SELECT
        plp.post_id,
        COUNT(DISTINCT plp.person_id) AS like_count
    FROM person_likes_post plp
    GROUP BY plp.post_id
),
post_tags AS (
    SELECT
        pht.post_id,
        t.id AS tag_id,
        t.name AS tag_name
    FROM post_has_tag_tag pht
    JOIN tag t ON pht.tag_id = t.id
),
forum_tag_counts AS (
    SELECT
        fp.forum_id,
        pt.tag_id,
        pt.tag_name,
        COUNT(*) AS tag_usage
    FROM forum_posts fp
    JOIN post_tags pt ON pt.post_id = fp.post_id
    GROUP BY fp.forum_id, pt.tag_id, pt.tag_name
),
forum_top_tag AS (
    SELECT
        forum_id,
        tag_name,
        tag_usage,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage DESC, tag_name) AS rn
    FROM forum_tag_counts
),
forum_aggregates AS (
    SELECT
        fp.forum_id,
        COUNT(DISTINCT fp.post_id) AS total_posts,
        AVG(fp.post_length) AS avg_post_length,
        COALESCE(SUM(pl.like_count), 0) AS total_likes
    FROM forum_posts fp
    LEFT JOIN post_likes pl ON pl.post_id = fp.post_id
    GROUP BY fp.forum_id
)
SELECT
    fi.forum_id,
    fi.forum_title,
    fa.total_posts,
    fa.total_likes,
    ROUND(fa.avg_post_length, 2) AS avg_post_length,
    ft.tag_name AS most_common_tag,
    mi.moderator_name
FROM forum_info fi
JOIN forum_aggregates fa ON fa.forum_id = fi.forum_id
LEFT JOIN forum_top_tag ft ON ft.forum_id = fi.forum_id AND ft.rn = 1
JOIN moderator_info mi ON mi.person_id = fi.moderator_person_id
ORDER BY fa.total_likes DESC
LIMIT 10
