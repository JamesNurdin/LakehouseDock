/*
  Trino analytical query – forum activity summary
  Shows post and comment counts, lengths, member and tag statistics, and like activity per forum.
*/
WITH forum_stats AS (
    SELECT
        f.id   AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id)                     AS post_count,
        COALESCE(SUM(p.length), 0)               AS total_post_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
comment_stats AS (
    SELECT
        f.id                                 AS forum_id,
        COUNT(DISTINCT c.id)                 AS comment_count,
        COALESCE(AVG(c.length), 0)           AS avg_comment_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
member_stats AS (
    SELECT
        f.id                                 AS forum_id,
        COUNT(DISTINCT fm.person_id)         AS member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_tag_stats AS (
    SELECT
        f.id                                 AS forum_id,
        COUNT(DISTINCT ft.tag_id)            AS forum_tag_count
    FROM forum f
    LEFT JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    GROUP BY f.id
),
post_tag_stats AS (
    SELECT
        f.id                                 AS forum_id,
        COUNT(DISTINCT pt.tag_id)            AS post_tag_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    GROUP BY f.id
),
post_like_stats AS (
    SELECT
        f.id                                 AS forum_id,
        COUNT(DISTINCT pl.person_id)         AS distinct_post_likers
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY f.id
),
comment_like_stats AS (
    SELECT
        f.id                                 AS forum_id,
        COUNT(DISTINCT cl.person_id)         AS distinct_comment_likers
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    GROUP BY f.id
)
SELECT
    fs.forum_id,
    fs.forum_title,
    fs.post_count,
    fs.total_post_length,
    CASE WHEN fs.post_count > 0 THEN fs.total_post_length * 1.0 / fs.post_count ELSE 0 END      AS avg_post_length,
    cs.comment_count,
    cs.avg_comment_length,
    ms.member_count,
    fts.forum_tag_count,
    pts.post_tag_count,
    pls.distinct_post_likers,
    cls.distinct_comment_likers,
    CASE WHEN fs.post_count > 0 THEN pls.distinct_post_likers * 1.0 / fs.post_count ELSE 0 END   AS avg_post_likers_per_post,
    CASE WHEN cs.comment_count > 0 THEN cls.distinct_comment_likers * 1.0 / cs.comment_count ELSE 0 END AS avg_comment_likers_per_comment
FROM forum_stats fs
LEFT JOIN comment_stats cs  ON cs.forum_id  = fs.forum_id
LEFT JOIN member_stats ms   ON ms.forum_id  = fs.forum_id
LEFT JOIN forum_tag_stats fts ON fts.forum_id = fs.forum_id
LEFT JOIN post_tag_stats pts ON pts.forum_id = fs.forum_id
LEFT JOIN post_like_stats pls ON pls.forum_id = fs.forum_id
LEFT JOIN comment_like_stats cls ON cls.forum_id = fs.forum_id
ORDER BY fs.total_post_length DESC
LIMIT 100
