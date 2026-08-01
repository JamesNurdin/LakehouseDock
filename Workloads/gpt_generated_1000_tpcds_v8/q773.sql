WITH cs_part AS (
    SELECT
        cd.cd_gender AS gender,
        p.p_channel_tv AS promo_tv,
        cs.cs_net_profit AS net_profit,
        ARRAY[cs.cs_quantity] AS qty_arr
    FROM tpcds.catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
    JOIN tpcds.date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_hours LIKE '%8AM-8AM%'
      AND EXISTS (
          SELECT 1
          FROM tpcds.promotion p2
          WHERE p2.p_promo_id = p.p_promo_id
            AND p2.p_channel_tv = 'Y'
      )
),
cs_exploded AS (
    SELECT gender, promo_tv, net_profit, qty
    FROM cs_part
    CROSS JOIN UNNEST(qty_arr) AS t(qty)
),
ws_part AS (
    SELECT
        cd.cd_gender AS gender,
        p.p_channel_tv AS promo_tv,
        ws.ws_net_profit AS net_profit,
        ARRAY[ws.ws_quantity] AS qty_arr
    FROM tpcds.web_sales ws
    TABLESAMPLE BERNOULLI (10)
    JOIN tpcds.date_dim d_sold_ws ON ws.ws_sold_date_sk = d_sold_ws.d_date_sk
    JOIN tpcds.date_dim d_ship_ws ON ws.ws_ship_date_sk = d_ship_ws.d_date_sk
    JOIN tpcds.customer c_ws ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE EXISTS (
        SELECT 1
        FROM tpcds.web_page wp2
        WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
          AND wp2.wp_type = 'product'
    )
),
ws_exploded AS (
    SELECT gender, promo_tv, net_profit, qty
    FROM ws_part
    CROSS JOIN UNNEST(qty_arr) AS t(qty)
),
union_all AS (
    SELECT gender, promo_tv, net_profit FROM cs_exploded
    UNION DISTINCT
    SELECT gender, promo_tv, net_profit FROM ws_exploded
)
SELECT
    gender,
    promo_tv,
    SUM(net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count
FROM union_all
GROUP BY gender, promo_tv
ORDER BY total_net_profit DESC
LIMIT 100
