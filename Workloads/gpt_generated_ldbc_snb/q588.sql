WITH forum_tag_stats AS (
   SELECT
       f.id,
       f.title,
       f.moderator_person_id,
       COUNT(*) AS tag_assignments,
       COUNT(DISTINCT ft.tag_id) AS distinct_tag_count,
       MIN(ft.creation_date) AS first_tag_assignment_date,
       MAX(ft.creation_date) AS last_tag_assignment_date
   FROM forum AS f
   JOIN forum_has_tag_tag AS ft
       ON ft.forum_id = f.id
   GROUP BY f.id, f.title, f.moderator_person_id
)
SELECT
   id,
   title,
   moderator_person_id,
   tag_assignments,
   distinct_tag_count,
   first_tag_assignment_date,
   last_tag_assignment_date
FROM forum_tag_stats
ORDER BY tag_assignments DESC
LIMIT 10
