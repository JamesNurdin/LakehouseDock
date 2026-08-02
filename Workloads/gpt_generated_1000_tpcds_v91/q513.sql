WITH avg_cat_profit AS (
    SELECT avg(cs_net_profit) AS avg_profit
    FROM catalog_sales
),
avg_web_profit AS (
    SELECT avg(ws_net_profit) AS avg_profit
    FROM web_sales
),
catalog_sales_expanded AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        cs.cs_order_number,
        cs.cs_net_profit,
        hour_part
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    CROSS JOIN UNNEST(split(cc.cc_hours, '-')) AS u (hour_part)
    WHERE cs.cs_net_profit > (SELECT avg_profit FROM avg_cat_profit)
),
web_sales_expanded AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        ws.ws_order_number,
        ws.ws_net_profit,
        url_part
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS u (url_part)
    WHERE ws.ws_net_profit > (SELECT avg_profit FROM avg_web_profit)
),
union_sales AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        cs_order_number AS order_number,
        cs_net_profit AS net_profit,
        'catalog' AS source,
        hour_part AS extra_info
    FROM catalog_sales_expanded
    UNION ALL
    SELECT
        c_customer_sk,
        c_customer_id,
        ws_order_number AS order_number,
        ws_net_profit AS net_profit,
        'web' AS source,
        url_part AS extra_info
    FROM web_sales_expanded
)
SELECT
    us.c_customer_id,
    us.source,
    us.net_profit,
    us.extra_info,
    ROW_NUMBER() OVER (PARTITION BY us.c_customer_id ORDER BY us.net_profit DESC) AS profit_rank
FROM union_sales us
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_customer_sk = us.c_customer_sk
)
  AND us.c_customer_id IN (
    SELECT c2.c_customer_id
    FROM customer c2
    WHERE c2.c_preferred_cust_flag = 'Y'
)
ORDER BY us.net_profit DESC
LIMIT 20
