SELECT
    cc.cc_market_manager,
    sm.sm_type,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MIN(cs.cs_sold_date_sk) AS min_sold_date_sk,
    MAX(cs.cs_sold_date_sk) AS max_sold_date_sk
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    cc.cc_rec_start_date >= DATE '2001-01-01'
    AND cc.cc_rec_end_date <= DATE '2001-12-31'
    AND sm.sm_carrier = 'MSC'
    AND sm.sm_type = 'EXPRESS'
    AND cp.cp_catalog_page_number BETWEEN 10 AND 20
    AND cc.cc_street_name = 'Sycamore'
GROUP BY
    cc.cc_market_manager,
    sm.sm_type
HAVING
    SUM(cs.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
