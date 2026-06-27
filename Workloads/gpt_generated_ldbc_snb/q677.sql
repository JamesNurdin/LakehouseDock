WITH tags_per_class AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT t.id) AS num_tags
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
),
comments_per_class AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT cht.comment_id) AS num_comments
    FROM comment_has_tag_tag cht
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
forums_per_class AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT fht.forum_id) AS num_forums
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
posts_per_class AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pht.post_id) AS num_posts
    FROM post_has_tag_tag pht
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
persons_interested_per_class AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pit.person_id) AS num_interested_persons
    FROM person_has_interest_tag pit
    JOIN tag t ON pit.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
friend_counts_per_class AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pkp.person1_id) AS num_friends_of_interested
    FROM person_knows_person pkp
    JOIN person p2 ON pkp.person2_id = p2.id
    JOIN person_has_interest_tag pit ON p2.id = pit.person_id
    JOIN tag t ON pit.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COALESCE(tpc.num_tags, 0) AS num_tags,
    COALESCE(cpc.num_comments, 0) AS num_comments,
    COALESCE(fpc.num_forums, 0) AS num_forums,
    COALESCE(ppc.num_posts, 0) AS num_posts,
    COALESCE(pip.num_interested_persons, 0) AS num_interested_persons,
    COALESCE(fcp.num_friends_of_interested, 0) AS num_friends_of_interested
FROM tag_class tc
LEFT JOIN tags_per_class tpc ON tc.id = tpc.tag_class_id
LEFT JOIN comments_per_class cpc ON tc.id = cpc.tag_class_id
LEFT JOIN forums_per_class fpc ON tc.id = fpc.tag_class_id
LEFT JOIN posts_per_class ppc ON tc.id = ppc.tag_class_id
LEFT JOIN persons_interested_per_class pip ON tc.id = pip.tag_class_id
LEFT JOIN friend_counts_per_class fcp ON tc.id = fcp.tag_class_id
ORDER BY num_interested_persons DESC, num_tags DESC
