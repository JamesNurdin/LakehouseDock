WITH sales_by_center AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM tpcds.call_center cc
    JOIN tpcds.catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_country = 'United States'
      AND cc.cc_rec_start_date >= DATE '2001-01-01'
      AND cc.cc_rec_end_date <= DATE '2005-12-31'
      AND cs.cs_sales_price > 20
    GROUP BY cc.cc_call_center_id, cc.cc_state
)
SELECT
    cc_state,
    cc_call_center_id,
    SUM(total_sales) AS sum_sales,
    SUM(total_profit) AS sum_profit,
    SUM(orders_cnt) AS sum_orders
FROM sales_by_center
GROUP BY CUBE(cc_state, cc_call_center_id)
ORDER BY
    CASE WHEN cc_state IS NULL THEN 1 ELSE 0 END,
    cc_state,
    cc_call_center_id
LIMIT 100
