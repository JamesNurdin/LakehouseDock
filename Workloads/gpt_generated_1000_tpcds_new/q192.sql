WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_warehouse_sk IN (5, 11)
    GROUP BY inv_date_sk, inv_item_sk
)
SELECT
    cp.cp_catalog_page_id,
    d.d_date,
    cp.cp_department,
    inv_agg.total_qty,
    wr.wr_return_amt_inc_tax,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY wr.wr_return_amt_inc_tax DESC) AS dept_return_rank,
    CASE WHEN wr.wr_return_amt_inc_tax > 1000 THEN 'high' ELSE 'low' END AS return_size_category,
    lat.sub_total_return
FROM catalog_page cp
INNER JOIN date_dim d
    ON cp.cp_start_date_sk = d.d_date_sk
INNER JOIN inv_agg
    ON inv_agg.inv_date_sk = d.d_date_sk
INNER JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
CROSS JOIN LATERAL (
    SELECT SUM(wr2.wr_return_amt_inc_tax) AS sub_total_return
    FROM web_returns wr2
    WHERE wr2.wr_returned_date_sk = d.d_date_sk
      AND wr2.wr_item_sk = inv_agg.inv_item_sk
) lat
WHERE d.d_year = 2001
  AND cp.cp_type = 'monthly'
  AND wr.wr_return_amt_inc_tax > 100
ORDER BY cp.cp_department, dept_return_rank
LIMIT 100
