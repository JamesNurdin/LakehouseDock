WITH tag_hierarchy AS (
   SELECT
      t.id AS tag_id,
      t.name AS tag_name,
      child.id AS child_class_id,
      child.name AS child_class_name,
      parent.id AS parent_class_id,
      parent.name AS parent_class_name
   FROM tag t
   JOIN tag_class child ON t.type_tag_class_id = child.id
   LEFT JOIN tag_class parent ON child.subclass_of_tag_class_id = parent.id
),

tag_person_counts AS (
   SELECT
      th.tag_id,
      th.tag_name,
      th.child_class_id,
      th.child_class_name,
      th.parent_class_id,
      th.parent_class_name,
      COUNT(DISTINCT pht.person_id) AS distinct_persons
   FROM person_has_interest_tag pht
   JOIN tag_hierarchy th ON pht.tag_id = th.tag_id
   GROUP BY th.tag_id, th.tag_name, th.child_class_id, th.child_class_name, th.parent_class_id, th.parent_class_name
),

parent_person_counts AS (
   SELECT
      th.parent_class_id,
      th.parent_class_name,
      COUNT(DISTINCT pht.person_id) AS parent_distinct_persons
   FROM person_has_interest_tag pht
   JOIN tag_hierarchy th ON pht.tag_id = th.tag_id
   GROUP BY th.parent_class_id, th.parent_class_name
)
SELECT
   tpc.parent_class_name,
   tpc.child_class_name,
   tpc.tag_name,
   tpc.distinct_persons,
   ppc.parent_distinct_persons,
   CAST(tpc.distinct_persons AS double) / NULLIF(ppc.parent_distinct_persons, 0) AS tag_person_ratio
FROM tag_person_counts tpc
JOIN parent_person_counts ppc ON tpc.parent_class_id = ppc.parent_class_id
ORDER BY tag_person_ratio DESC
LIMIT 10
