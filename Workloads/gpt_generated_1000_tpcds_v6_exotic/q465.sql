WITH ws_agg AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_warehouse_sk,
        ws_web_site_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_qty,
        AVG(ws_sales_price) AS avg_unit_price,
        COUNT(*) AS order_cnt
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2452000                 -- filter on sold date surrogate key
      AND ws_ext_discount_amt > 10                                    -- discount filter
      AND ws_net_profit > 0                                           -- profit filter
      AND ws_quantity >= 1                                            -- quantity filter
    GROUP BY ws_bill_customer_sk, ws_item_sk, ws_warehouse_sk, ws_web_site_sk
)
SELECT
    w.w_state,
    s.web_name,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ws_agg.total_sales) AS state_site_sales,
    AVG(ws_agg.avg_unit_price) AS avg_price,
    CASE WHEN SUM(ws_agg.total_sales) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
FROM ws_agg
JOIN customer c               ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN item i                    ON ws_agg.ws_item_sk = i.i_item_sk
JOIN warehouse w               ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site s                ON ws_agg.ws_web_site_sk = s.web_site_sk
WHERE cd.cd_purchase_estimate >= 5000       -- purchase estimate filter
  AND cd.cd_marital_status = 'M'            -- marital status filter
  AND c.c_salutation = 'Mr.'                -- salutation filter
  AND i.i_class = 'furniture'              -- product class filter
  AND w.w_state = 'CA'                      -- warehouse state filter
GROUP BY w.w_state, s.web_name
ORDER BY state_site_sales DESC
LIMIT 100
