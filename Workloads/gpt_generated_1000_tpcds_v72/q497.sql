WITH catalog_part AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_ship_mode_sk AS ship_mode_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_net_profit AS net_profit,
        cs.cs_sold_date_sk AS sold_date_sk
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_state = 'CA'
      AND ca.ca_state = 'CA'
      AND p.p_channel_press = 'N'
      AND sm.sm_type = 'AIR'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
),
web_part AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_bill_customer_sk AS customer_sk,
        NULL AS call_center_sk,
        ws.ws_ship_mode_sk AS ship_mode_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_ext_sales_price AS ext_sales_price,
        ws.ws_net_profit AS net_profit,
        ws.ws_sold_date_sk AS sold_date_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ca.ca_state = 'CA'
      AND p.p_channel_press = 'N'
      AND sm.sm_type = 'AIR'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
),
combined_sales AS (
    SELECT * FROM catalog_part
    UNION ALL
    SELECT * FROM web_part
),
aggregated AS (
    SELECT
        customer_sk,
        SUM(ext_sales_price) AS total_sales,
        SUM(net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM combined_sales
    GROUP BY customer_sk
)
SELECT DISTINCT
    a.customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    a.total_sales,
    a.total_profit,
    a.sales_cnt,
    ROW_NUMBER() OVER (ORDER BY a.total_profit DESC) AS profit_rank,
    DENSE_RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank
FROM aggregated a
JOIN customer c ON a.customer_sk = c.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM customer_address ca
    WHERE ca.ca_address_sk = c.c_current_addr_sk
      AND ca.ca_state = 'CA'
)
ORDER BY a.total_profit DESC
LIMIT 100
