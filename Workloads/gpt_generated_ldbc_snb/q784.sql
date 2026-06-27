WITH person_tag_counts AS (
    SELECT p.id AS person_id,
           p.gender,
           p.language,
           COUNT(DISTINCT pt.tag_id) AS tag_count
    FROM person p
    JOIN person_has_interest_tag pt
      ON pt.person_id = p.id
    GROUP BY p.id, p.gender, p.language
),

gender_language_stats AS (
    SELECT gender,
           language,
           COUNT(*) AS person_cnt,
           AVG(tag_count) AS avg_tags,
           MAX(tag_count) AS max_tags,
           MIN(tag_count) AS min_tags
    FROM person_tag_counts
    GROUP BY gender, language
)
SELECT gender,
       language,
       person_cnt,
       avg_tags,
       max_tags,
       min_tags,
       ROW_NUMBER() OVER (PARTITION BY gender ORDER BY person_cnt DESC) AS language_rank
FROM gender_language_stats
ORDER BY gender, language_rank
LIMIT 50
