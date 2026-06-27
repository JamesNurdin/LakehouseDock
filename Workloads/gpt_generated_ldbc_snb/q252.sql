WITH joined AS (
    SELECT
        p.id AS post_id,
        p.length AS post_length,
        p.language AS post_language,
        p.browser_used AS post_browser,
        p.creator_person_id AS creator_id,
        t.id AS tag_id,
        t.name AS tag_name,
        t.type_tag_class_id AS tag_type_id
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
),
tag_agg AS (
    SELECT
        tag_id,
        tag_name,
        tag_type_id,
        COUNT(DISTINCT post_id) AS total_posts,
        AVG(post_length) AS avg_post_length,
        COUNT(DISTINCT creator_id) AS distinct_creators
    FROM joined
    GROUP BY tag_id, tag_name, tag_type_id
),
browser_rank AS (
    SELECT
        tag_id,
        post_browser,
        COUNT(*) AS browser_cnt,
        ROW_NUMBER() OVER (PARTITION BY tag_id ORDER BY COUNT(*) DESC) AS rn
    FROM joined
    GROUP BY tag_id, post_browser
),
top_browser AS (
    SELECT
        tag_id,
        post_browser AS top_browser,
        browser_cnt AS top_browser_cnt
    FROM browser_rank
    WHERE rn = 1
),
language_rank AS (
    SELECT
        tag_id,
        post_language,
        COUNT(*) AS language_cnt,
        ROW_NUMBER() OVER (PARTITION BY tag_id ORDER BY COUNT(*) DESC) AS rn
    FROM joined
    GROUP BY tag_id, post_language
),
top_languages AS (
    SELECT
        tag_id,
        post_language AS language,
        language_cnt
    FROM language_rank
    WHERE rn <= 3
)
SELECT
    ta.tag_name,
    ta.tag_type_id,
    ta.total_posts,
    ta.avg_post_length,
    ta.distinct_creators,
    tb.top_browser,
    tb.top_browser_cnt,
    tl.language,
    tl.language_cnt
FROM tag_agg ta
LEFT JOIN top_browser tb ON ta.tag_id = tb.tag_id
LEFT JOIN top_languages tl ON ta.tag_id = tl.tag_id
ORDER BY ta.total_posts DESC, ta.tag_name
