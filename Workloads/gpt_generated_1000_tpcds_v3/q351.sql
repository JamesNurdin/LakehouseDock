WITH wr_agg AS (
    SELECT
        wr_returned_date_sk,
        SUM(wr_return_amt) AS sum_wr_return_amt,
        AVG(wr_return_amt) AS avg_wr_return_amt,
        COUNT(DISTINCT wr_order_number) AS cnt_distinct_wr_order,
        MAX(wr_return_amt) AS max_wr_return_amt
    FROM web_returns
    GROUP BY wr_returned_date_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    sm.sm_ship_mode_id,
    d.d_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    MIN(cr.cr_return_quantity) AS min_return_quantity,
    MAX(cr.cr_return_quantity) AS max_return_quantity,
    SUM(wr_agg.sum_wr_return_amt) AS total_web_return_amount,
    AVG(wr_agg.avg_wr_return_amt) AS avg_web_return_amt,
    SUM(wr_agg.cnt_distinct_wr_order) AS total_distinct_web_orders,
    MAX(wr_agg.max_wr_return_amt) AS max_web_return_amt,
    (SELECT SUM(cr2.cr_net_loss)
     FROM catalog_returns cr2
     WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk) AS total_net_loss_by_ship_mode
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN wr_agg
    ON wr_agg.wr_returned_date_sk = d.d_date_sk
WHERE d.d_moy = 9
  AND sm.sm_carrier = 'GREAT EASTERN'
  AND cp.cp_catalog_number = 10
  AND d.d_date BETWEEN DATE '2001-09-01' AND DATE '2001-09-30'
  AND EXISTS (
      SELECT 1
      FROM web_returns wr2
      WHERE wr2.wr_returned_date_sk = d.d_date_sk
        AND wr2.wr_return_amt > 0
  )
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    sm.sm_ship_mode_id,
    sm.sm_ship_mode_sk,
    d.d_year
HAVING SUM(cr.cr_return_amount) > 1000
   AND COUNT(DISTINCT cr.cr_order_number) > 5
ORDER BY total_return_amount DESC
LIMIT 100
