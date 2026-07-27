WITH sales_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship > 1000
      AND cs.cs_quantity > 5
    GROUP BY cs.cs_call_center_sk, cs.cs_sold_date_sk
)
SELECT
    cc.cc_name,
    cc.cc_market_manager,
    d_sold.d_year,
    d_sold.d_fy_quarter_seq,
    sa.total_net_paid,
    sa.avg_wholesale_cost,
    sa.sales_cnt,
    (
        SELECT MAX(cs2.cs_net_paid_inc_ship)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
    ) AS max_net_paid
FROM sales_agg sa
JOIN tpcds.call_center cc
  ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.date_dim d_sold
  ON sa.cs_sold_date_sk = d_sold.d_date_sk
WHERE cc.cc_state = 'CA'
  AND cc.cc_zip = '41933'
  AND d_sold.d_year = 2001
  AND d_sold.d_fy_quarter_seq = 8
  AND cc.cc_market_manager LIKE '%Group%'
ORDER BY sa.total_net_paid DESC
LIMIT 100
