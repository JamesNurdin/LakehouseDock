/* goal: Combine catalog and web sales that were part of TV promotions, showing order details and profitability per channel */
WITH catalog_data AS (
    SELECT
        cs.cs_order_number AS order_number,
        'Catalog' AS sales_channel,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit
    FROM tpcds.catalog_sales cs
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE p.p_channel_tv = 'Y'
),
web_data AS (
    SELECT
        ws.ws_order_number AS order_number,
        'Web' AS sales_channel,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
    FROM tpcds.web_sales ws
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE p.p_channel_tv = 'Y'
)
SELECT order_number, sales_channel, net_paid, net_profit
FROM catalog_data
UNION ALL
SELECT order_number, sales_channel, net_paid, net_profit
FROM web_data
ORDER BY net_paid DESC
LIMIT 100
