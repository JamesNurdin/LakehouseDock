WITH sampled AS (
  SELECT *
  FROM tpcds.customer TABLESAMPLE BERNOULLI (10)
),

sel1 AS (
  SELECT c.c_customer_id,
         cd.cd_gender,
         cd.cd_purchase_estimate,
         ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank,
         part AS birth_part
  FROM sampled c
  JOIN tpcds.customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
  CROSS JOIN UNNEST(ARRAY[c.c_birth_day, c.c_birth_month, c.c_birth_year]) AS t(part)
  WHERE cd.cd_purchase_estimate > 1000
),

sel2 AS (
  SELECT c.c_customer_id,
         cd.cd_gender,
         cd.cd_purchase_estimate,
         ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank,
         part AS birth_part
  FROM tpcds.customer c
  JOIN tpcds.customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
  CROSS JOIN UNNEST(ARRAY[c.c_birth_day, c.c_birth_month, c.c_birth_year]) AS t(part)
  WHERE cd.cd_purchase_estimate <= 2000
),

unioned AS (
  SELECT c_customer_id, cd_gender, cd_purchase_estimate, gender_rank, birth_part
  FROM sel1
  UNION
  SELECT c_customer_id, cd_gender, cd_purchase_estimate, gender_rank, birth_part
  FROM sel2
),

intersected_ids AS (
  SELECT c_customer_id
  FROM sel1
  INTERSECT
  SELECT c_customer_id
  FROM sel2
)

SELECT u.c_customer_id,
       u.cd_gender,
       u.cd_purchase_estimate,
       u.gender_rank,
       u.birth_part
FROM unioned u
WHERE u.c_customer_id IN (SELECT c_customer_id FROM intersected_ids)
ORDER BY u.cd_purchase_estimate DESC
LIMIT 100
