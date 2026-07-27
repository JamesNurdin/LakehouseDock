WITH filtered_customers AS (
    SELECT c_customer_sk, c_customer_id, c_salutation
    FROM customer
    WHERE c_salutation = 'Mr.'
),
catalog_with_web AS (
    SELECT cs.cs_sold_date_sk,
           cs.cs_call_center_sk,
           cs.cs_catalog_page_sk,
           cs.cs_warehouse_sk,
           cs.cs_order_number,
           cs.cs_net_paid,
           cs.cs_net_profit,
           cs.cs_bill_customer_sk,
           cs.cs_bill_hdemo_sk
    FROM catalog_sales cs
    WHERE EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_order_number = cs.cs_order_number
    )
)
SELECT
    cc.cc_name,
    cp.cp_department,
    s.s_store_name,
    d_sold.d_year,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    AVG(cs.cs_net_profit) AS avg_catalog_profit,
    MIN(ws.ws_net_paid) AS min_web_payment,
    MAX(ws.ws_net_paid) AS max_web_payment
FROM catalog_with_web cs
JOIN filtered_customers c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE
    d_sold.d_moy = 9
    AND hd.hd_dep_count >= 4
    AND cc.cc_state = 'CA'
GROUP BY
    cc.cc_name,
    cp.cp_department,
    s.s_store_name,
    d_sold.d_year
ORDER BY total_catalog_sales DESC
LIMIT 100
