WITH
  closed_sample AS (
    SELECT
      s_store_sk,
      s_store_name,
      s_state,
      s_floor_space,
      s_number_employees,
      s_tax_percentage,
      s_closed_date_sk
    FROM store
    TABLESAMPLE BERNOULLI (10)
    WHERE s_closed_date_sk IS NOT NULL
      AND s_state = 'CA'
      AND s_floor_space > 5000
      AND s_number_employees BETWEEN 10 AND 200
      AND s_tax_percentage < 5
  ),
  open_sample AS (
    SELECT
      s_store_sk,
      s_store_name,
      s_state,
      s_floor_space,
      s_number_employees,
      s_tax_percentage,
      s_closed_date_sk
    FROM store
    WHERE s_closed_date_sk IS NULL
      AND s_state = 'NY'
      AND s_floor_space > 8000
      AND s_number_employees > 50
      AND s_tax_percentage BETWEEN 4 AND 10
  ),
  closed_not_open AS (
    SELECT s_store_sk FROM closed_sample
    EXCEPT
    SELECT s_store_sk FROM open_sample
  ),
  union_set AS (
    SELECT s_store_sk FROM closed_not_open
    UNION
    SELECT s_store_sk FROM store
    WHERE s_state = 'TX' AND s_floor_space BETWEEN 3000 AND 6000
  ),
  filtered_store AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      s.s_floor_space,
      s.s_number_employees,
      s.s_tax_percentage,
      d.d_date,
      d.d_year,
      ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY s.s_floor_space DESC) AS rn_state_floor_rank,
      RANK() OVER (ORDER BY s.s_floor_space DESC) AS global_floor_rank
    FROM store s
    INNER JOIN date_dim d
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_store_sk IN (SELECT s_store_sk FROM union_set)
      AND EXISTS (
        SELECT 1 FROM date_dim d2
        WHERE d2.d_year = 1998
          AND d2.d_date = s.s_rec_start_date
      )
      AND s.s_tax_percentage <= 7
      AND s.s_number_employees <> 0
      AND s.s_state IN ('CA', 'NY', 'TX')
  )
SELECT
  f.s_store_sk,
  f.s_store_name,
  f.s_state,
  f.s_floor_space,
  f.s_number_employees,
  f.s_tax_percentage,
  f.d_date,
  f.d_year,
  f.rn_state_floor_rank,
  f.global_floor_rank
FROM filtered_store f
WHERE f.rn_state_floor_rank <= 5
ORDER BY f.global_floor_rank ASC
LIMIT 100
