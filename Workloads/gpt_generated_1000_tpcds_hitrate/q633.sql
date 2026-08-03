WITH sales_agg AS (
    SELECT d.d_year,
           COUNT(DISTINCT cs.cs_item_sk)                      AS metric_a,
           SUM(DISTINCT cs.cs_sales_price)                    AS metric_b,
           cc.cc_name                                         AS descriptor
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, cc.cc_name
)
SELECT sales_agg.d_year,
       sales_agg.metric_a,
       sales_agg.metric_b,
       sales_agg.descriptor
FROM sales_agg
UNION ALL
SELECT d.d_year,
       COUNT(DISTINCT cr.cr_reason_sk) AS metric_a,
       SUM(cr.cr_net_loss)             AS metric_b,
       w.w_warehouse_name              AS descriptor
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs
        WHERE cs.cs_order_number = cr.cr_order_number
          AND cs.cs_sold_date_sk = cr.cr_returned_date_sk
    )
GROUP BY d.d_year, w.w_warehouse_name
ORDER BY metric_a DESC, metric_b DESC
LIMIT 100
