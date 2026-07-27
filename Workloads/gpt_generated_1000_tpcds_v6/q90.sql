WITH filtered_returns AS (
  SELECT
    cr.cr_warehouse_sk,
    w.w_warehouse_id,
    w.w_street_name,
    w.w_city,
    w.w_state,
    w.w_county,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    d.d_year
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2001
    AND regexp_like(w.w_street_name, '(?i)^(North|Elm)')
    AND w.w_county LIKE '%County'
    AND EXISTS (
      SELECT 1
      FROM promotion p
      WHERE p.p_item_sk = cr.cr_item_sk
        AND cr.cr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    )
)
SELECT DISTINCT
  fw.w_warehouse_id AS warehouse_id,
  concat(fw.w_city, ', ', fw.w_state) AS location,
  substring(fw.w_street_name, 1, 3) AS street_prefix,
  regexp_extract(fw.w_street_name, '(North|Elm)', 1) AS street_match,
  SUM(fw.cr_return_amount) AS total_return_amount,
  SUM(fw.cr_return_quantity) AS total_return_quantity,
  AVG(SUM(fw.cr_return_amount)) OVER (PARTITION BY fw.w_warehouse_id) AS avg_return_amount_per_warehouse,
  CASE
    WHEN SUM(fw.cr_return_amount) > AVG(SUM(fw.cr_return_amount)) OVER (PARTITION BY fw.w_warehouse_id)
    THEN 'ABOVE_AVG'
    ELSE 'BELOW_AVG'
  END AS performance
FROM filtered_returns fw
GROUP BY
  fw.w_warehouse_id,
  fw.w_city,
  fw.w_state,
  fw.w_street_name
ORDER BY total_return_amount DESC
LIMIT 100
