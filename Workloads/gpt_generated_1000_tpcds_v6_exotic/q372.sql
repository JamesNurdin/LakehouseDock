WITH distinct_reasons AS (
  SELECT DISTINCT r_reason_sk, r_reason_id, r_reason_desc
  FROM reason
  WHERE regexp_like(r_reason_desc, '^Not.*working')
),
filtered_returns AS (
  SELECT
    cr.cr_warehouse_sk,
    cr.cr_reason_sk,
    cr.cr_order_number,
    cr.cr_net_loss,
    cp.cp_description,
    td.t_hour
  FROM catalog_returns cr
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
  WHERE cp.cp_description LIKE '%-%'
    AND td.t_hour BETWEEN 9 AND 17
)
SELECT
  w.w_warehouse_id,
  w.w_city,
  dr.r_reason_id,
  COUNT(DISTINCT fr.cr_order_number) AS distinct_orders,
  SUM(fr.cr_net_loss) AS total_net_loss,
  REGEXP_EXTRACT(fr.cp_description, '\\d+', 0) AS extracted_code,
  RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(fr.cr_net_loss) DESC) AS loss_rank
FROM filtered_returns fr
JOIN distinct_reasons dr
  ON fr.cr_reason_sk = dr.r_reason_sk
JOIN warehouse w
  ON fr.cr_warehouse_sk = w.w_warehouse_sk
GROUP BY
  w.w_warehouse_id,
  w.w_city,
  dr.r_reason_id,
  REGEXP_EXTRACT(fr.cp_description, '\\d+', 0)
ORDER BY total_net_loss DESC
LIMIT 100
