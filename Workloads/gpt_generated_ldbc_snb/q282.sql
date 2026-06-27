WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date,
        p.id AS post_id,
        p.length AS post_length,
        p.creator_person_id AS post_creator_id
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
),
post_likes AS (
    SELECT
        fp.forum_id,
        COUNT(*) AS likes_on_posts
    FROM forum_posts fp
    JOIN person_likes_post plp ON plp.post_id = fp.post_id
    GROUP BY fp.forum_id
),
forum_comments AS (
    SELECT
        fp.forum_id,
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id AS comment_creator_id
    FROM forum_posts fp
    JOIN comment c ON c.parent_post_id = fp.post_id
),
comment_likes AS (
    SELECT
        fc.forum_id,
        COUNT(*) AS likes_on_comments
    FROM forum_comments fc
    JOIN person_likes_comment plc ON plc.comment_id = fc.comment_id
    GROUP BY fc.forum_id
),
forum_participants AS (
    SELECT forum_id, post_creator_id AS creator_id FROM forum_posts
    UNION
    SELECT forum_id, comment_creator_id AS creator_id FROM forum_comments
),
participants_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT creator_id) AS distinct_participants
    FROM forum_participants
    GROUP BY forum_id
),
forum_tags AS (
    SELECT
        fp.forum_id,
        pht.tag_id
    FROM forum_posts fp
    JOIN post_has_tag_tag pht ON pht.post_id = fp.post_id
    UNION
    SELECT
        fc.forum_id,
        cht.tag_id
    FROM forum_comments fc
    JOIN comment_has_tag_tag cht ON cht.comment_id = fc.comment_id
),
forum_tag_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT tag_id) AS distinct_tags_used
    FROM forum_tags
    GROUP BY forum_id
),
post_counts AS (
    SELECT forum_id, COUNT(*) AS total_posts
    FROM forum_posts
    GROUP BY forum_id
),
comment_counts AS (
    SELECT forum_id, COUNT(*) AS total_comments
    FROM forum_comments
    GROUP BY forum_id
),
post_avg_length AS (
    SELECT forum_id, AVG(post_length) AS avg_post_length
    FROM forum_posts
    GROUP BY forum_id
),
comment_avg_length AS (
    SELECT forum_id, AVG(comment_length) AS avg_comment_length
    FROM forum_comments
    GROUP BY forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    COALESCE(pc.total_posts, 0) AS total_posts,
    COALESCE(cc.total_comments, 0) AS total_comments,
    COALESCE(pl.likes_on_posts, 0) AS total_likes_on_posts,
    COALESCE(cl.likes_on_comments, 0) AS total_likes_on_comments,
    COALESCE(pcnt.distinct_participants, 0) AS distinct_participants,
    COALESCE(pal.avg_post_length, 0) AS avg_post_length,
    COALESCE(cal.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(tcnt.distinct_tags_used, 0) AS distinct_tags_used
FROM forum f
LEFT JOIN post_counts pc ON pc.forum_id = f.id
LEFT JOIN comment_counts cc ON cc.forum_id = f.id
LEFT JOIN post_likes pl ON pl.forum_id = f.id
LEFT JOIN comment_likes cl ON cl.forum_id = f.id
LEFT JOIN participants_counts pcnt ON pcnt.forum_id = f.id
LEFT JOIN post_avg_length pal ON pal.forum_id = f.id
LEFT JOIN comment_avg_length cal ON cal.forum_id = f.id
LEFT JOIN forum_tag_counts tcnt ON tcnt.forum_id = f.id
ORDER BY total_posts DESC
LIMIT 10
