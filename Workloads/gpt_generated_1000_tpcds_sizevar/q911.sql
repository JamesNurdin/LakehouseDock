WITH sampled_catalog AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 2
),
sampled_web AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_quantity > 2
),
union_sales AS (
    SELECT
        c.c_customer_id                AS customer_id,
        CASE WHEN sm.sm_carrier = 'FEDEX' THEN 'Express' ELSE 'Standard' END AS shipping_category,
        cs.cs_ext_sales_price          AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY sm.sm_code ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank,
        td.t_hour                      AS sale_hour,
        CASE WHEN cs.cs_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS sales_tier
    FROM sampled_catalog cs
    JOIN customer c       ON cs.cs_bill_customer_sk   = c.c_customer_sk
    JOIN ship_mode sm    ON cs.cs_ship_mode_sk      = sm.sm_ship_mode_sk
    JOIN time_dim td     ON cs.cs_sold_time_sk      = td.t_time_sk
    UNION
    SELECT
        c.c_customer_id                AS customer_id,
        CASE WHEN sm.sm_carrier = 'FEDEX' THEN 'Express' ELSE 'Standard' END AS shipping_category,
        ws.ws_ext_sales_price          AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY sm.sm_code ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank,
        td.t_hour                      AS sale_hour,
        CASE WHEN ws.ws_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS sales_tier
    FROM sampled_web ws
    JOIN customer c       ON ws.ws_bill_customer_sk   = c.c_customer_sk
    JOIN ship_mode sm    ON ws.ws_ship_mode_sk       = sm.sm_ship_mode_sk
    JOIN time_dim td     ON ws.ws_sold_time_sk       = td.t_time_sk
),
excluded_customers AS (
    SELECT c_customer_id FROM customer WHERE c_preferred_cust_flag = 'Y'
),
final_set AS (
    SELECT * FROM union_sales
    EXCEPT
    SELECT us.customer_id,
           us.shipping_category,
           us.total_sales,
           us.sales_rank,
           us.sale_hour,
           us.sales_tier
    FROM union_sales us
    JOIN excluded_customers ec ON us.customer_id = ec.c_customer_id
)
SELECT *
FROM final_set
ORDER BY total_sales DESC, sales_rank
LIMIT 100
