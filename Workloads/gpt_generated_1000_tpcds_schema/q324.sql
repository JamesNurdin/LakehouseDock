WITH aggregated_returns AS (
  SELECT
    r.r_reason_desc,
    dd.d_year,
    SUM(cr.cr_return_amount) AS catalog_return_sum,
    SUM(sr.sr_return_amt) AS store_return_sum,
    COUNT(*) FILTER (WHERE cr.cr_return_amount IS NOT NULL) AS catalog_cnt,
    COUNT(*) FILTER (WHERE sr.sr_return_amt IS NOT NULL) AS store_cnt
  FROM catalog_returns cr
  INNER JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
  INNER JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  FULL OUTER JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  INNER JOIN inventory i ON dd.d_date_sk = i.inv_date_sk
  INNER JOIN store_returns sr
    ON dd.d_date_sk = sr.sr_returned_date_sk
   AND td.t_time_sk = sr.sr_return_time_sk
   AND r.r_reason_sk = sr.sr_reason_sk
  WHERE dd.d_year = 1998
    AND td.t_hour BETWEEN 9 AND 17
    AND cr.cr_return_amount > 100
    AND sr.sr_return_amt > 50
    AND i.inv_quantity_on_hand < 500
    AND r.r_reason_desc LIKE '%price%'
  GROUP BY r.r_reason_desc, dd.d_year
)
SELECT
  ar.r_reason_desc,
  ar.d_year,
  ar.catalog_return_sum,
  ar.store_return_sum,
  (ar.catalog_return_sum + ar.store_return_sum) AS total_return_sum,
  (ar.catalog_return_sum + ar.store_return_sum) / NULLIF(ar.catalog_cnt + ar.store_cnt, 0) AS avg_return_per_transaction,
  (
    SELECT MAX(inv_quantity_on_hand)
    FROM inventory
    WHERE inv_date_sk = (
      SELECT MAX(inv_date_sk) FROM inventory
    )
  ) AS max_inventory_qty
FROM aggregated_returns ar
WHERE (ar.catalog_return_sum + ar.store_return_sum) > 1000
ORDER BY total_return_sum DESC
LIMIT 100
