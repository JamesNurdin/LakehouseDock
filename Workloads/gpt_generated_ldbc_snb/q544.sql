WITH
    comment_likes AS (
        SELECT
            comment_id,
            COUNT(person_id) AS like_count
        FROM person_likes_comment
        GROUP BY comment_id
    ),
    comment_tags AS (
        SELECT
            ct.comment_id,
            ct.tag_id,
            t.name AS tag_name
        FROM comment_has_tag_tag ct
        JOIN tag t ON ct.tag_id = t.id
    ),
    comment_stats AS (
        SELECT
            c.id AS comment_id,
            c.length AS comment_length,
            COALESCE(cl.like_count, 0) AS like_count,
            p.container_forum_id AS forum_id
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        LEFT JOIN comment_likes cl ON cl.comment_id = c.id
    ),
    forum_comment_agg AS (
        SELECT
            f.id AS forum_id,
            f.title AS forum_title,
            COUNT(cs.comment_id) AS total_comments,
            AVG(cs.comment_length) AS avg_comment_length,
            SUM(cs.like_count) AS total_comment_likes
        FROM forum f
        JOIN comment_stats cs ON cs.forum_id = f.id
        GROUP BY f.id, f.title
    ),
    forum_tag_usage AS (
        SELECT
            cs.forum_id,
            ct.tag_id,
            ct.tag_name,
            COUNT(DISTINCT ct.comment_id) AS comment_count_using_tag
        FROM comment_tags ct
        JOIN comment_stats cs ON cs.comment_id = ct.comment_id
        GROUP BY cs.forum_id, ct.tag_id, ct.tag_name
    ),
    forum_tag_summary AS (
        SELECT
            ft.forum_id,
            COUNT(DISTINCT ft.tag_id) AS distinct_tag_count
        FROM forum_tag_usage ft
        GROUP BY ft.forum_id
    ),
    forum_top_tag AS (
        SELECT
            ft.forum_id,
            ft.tag_name AS top_tag_name,
            ft.comment_count_using_tag AS top_tag_comment_count,
            ROW_NUMBER() OVER (PARTITION BY ft.forum_id ORDER BY ft.comment_count_using_tag DESC) AS rn
        FROM forum_tag_usage ft
    ),
    forum_member_counts AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT fmp.person_id) AS member_count
        FROM forum f
        LEFT JOIN forum_has_member_person fmp ON fmp.forum_id = f.id
        GROUP BY f.id
    )
SELECT
    fca.forum_id,
    fca.forum_title,
    fca.total_comments,
    fca.avg_comment_length,
    fca.total_comment_likes,
    COALESCE(fms.member_count, 0) AS member_count,
    COALESCE(fts.distinct_tag_count, 0) AS distinct_tag_count,
    ft.top_tag_name,
    ft.top_tag_comment_count
FROM forum_comment_agg fca
LEFT JOIN forum_member_counts fms ON fms.forum_id = fca.forum_id
LEFT JOIN forum_tag_summary fts ON fts.forum_id = fca.forum_id
LEFT JOIN (
    SELECT forum_id, top_tag_name, top_tag_comment_count
    FROM forum_top_tag
    WHERE rn = 1
) ft ON ft.forum_id = fca.forum_id
ORDER BY fca.total_comments DESC
LIMIT 20
