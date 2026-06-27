WITH post_like_counts AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(pl.person_id) AS post_like_cnt,
        COUNT(DISTINCT pl.person_id) AS distinct_person_like_cnt_post
    FROM tag t
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY t.id, t.name
),
comment_like_counts AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(cl.person_id) AS comment_like_cnt,
        COUNT(DISTINCT cl.person_id) AS distinct_person_like_cnt_comment
    FROM tag t
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY t.id, t.name
),
combined AS (
    SELECT
        COALESCE(p.tag_id, c.tag_id) AS tag_id,
        COALESCE(p.tag_name, c.tag_name) AS tag_name,
        COALESCE(p.post_like_cnt, 0) AS post_like_cnt,
        COALESCE(p.distinct_person_like_cnt_post, 0) AS distinct_person_like_cnt_post,
        COALESCE(c.comment_like_cnt, 0) AS comment_like_cnt,
        COALESCE(c.distinct_person_like_cnt_comment, 0) AS distinct_person_like_cnt_comment,
        COALESCE(p.post_like_cnt, 0) + COALESCE(c.comment_like_cnt, 0) AS total_like_cnt,
        COALESCE(p.distinct_person_like_cnt_post, 0) + COALESCE(c.distinct_person_like_cnt_comment, 0) AS total_distinct_person_like_cnt
    FROM post_like_counts p
    FULL OUTER JOIN comment_like_counts c
        ON p.tag_id = c.tag_id
),
ranked_tags AS (
    SELECT
        tag_id,
        tag_name,
        total_like_cnt,
        total_distinct_person_like_cnt,
        post_like_cnt,
        comment_like_cnt,
        row_number() OVER (ORDER BY total_like_cnt DESC) AS tag_rank
    FROM combined
)
SELECT
    tag_id,
    tag_name,
    total_like_cnt,
    total_distinct_person_like_cnt,
    post_like_cnt,
    comment_like_cnt,
    tag_rank
FROM ranked_tags
WHERE tag_rank <= 10
ORDER BY tag_rank
