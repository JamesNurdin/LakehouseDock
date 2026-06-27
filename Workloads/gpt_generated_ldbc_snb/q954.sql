-- Tag usage and interest analysis: counts of comments, forums, posts and gender breakdown of interested persons per tag
WITH tag_counts AS (
    SELECT
        t.id   AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT cht.comment_id) AS comment_cnt,
        COUNT(DISTINCT fht.forum_id)   AS forum_cnt,
        COUNT(DISTINCT pht.post_id)    AS post_cnt
    FROM tag t
    LEFT JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    LEFT JOIN forum_has_tag_tag  fht ON fht.tag_id = t.id
    LEFT JOIN post_has_tag_tag   pht ON pht.tag_id = t.id
    GROUP BY t.id, t.name
),
tag_person_gender AS (
    SELECT
        t.id   AS tag_id,
        t.name AS tag_name,
        p.gender AS gender,
        COUNT(DISTINCT pit.person_id) AS person_cnt
    FROM tag t
    JOIN person_has_interest_tag pit ON pit.tag_id = t.id
    JOIN person p                   ON pit.person_id = p.id
    GROUP BY t.id, t.name, p.gender
)
SELECT
    tc.tag_id,
    tc.tag_name,
    tc.comment_cnt,
    tc.forum_cnt,
    tc.post_cnt,
    COALESCE(SUM(CASE WHEN tpg.gender = 'male'   THEN tpg.person_cnt END), 0) AS male_person_cnt,
    COALESCE(SUM(CASE WHEN tpg.gender = 'female' THEN tpg.person_cnt END), 0) AS female_person_cnt,
    COALESCE(SUM(tpg.person_cnt), 0)                                            AS total_person_cnt,
    (tc.comment_cnt + tc.forum_cnt + tc.post_cnt + COALESCE(SUM(tpg.person_cnt), 0)) AS total_usage
FROM tag_counts tc
LEFT JOIN tag_person_gender tpg ON tpg.tag_id = tc.tag_id
GROUP BY
    tc.tag_id,
    tc.tag_name,
    tc.comment_cnt,
    tc.forum_cnt,
    tc.post_cnt
ORDER BY total_usage DESC
LIMIT 10
