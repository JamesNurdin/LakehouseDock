WITH ws_agg AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS item_sales,
        SUM(ws.ws_quantity) AS total_qty
    FROM
        web_sales ws TABLESAMPLE BERNOULLI (10)
    GROUP BY
        ws.ws_item_sk
)
SELECT
    i.i_manufact,
    i.i_category,
    chdemo.hd_income_band_sk,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT bcust.c_customer_sk) AS bill_customer_cnt,
    COUNT(DISTINCT scust.c_customer_sk) AS ship_customer_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    t.tier
FROM
    ws_agg
    JOIN web_sales ws ON ws.ws_item_sk = ws_agg.ws_item_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p_web ON ws.ws_promo_sk = p_web.p_promo_sk
    JOIN promotion p_item ON i.i_item_sk = p_item.p_item_sk
    JOIN customer bcust ON ws.ws_bill_customer_sk = bcust.c_customer_sk
    JOIN household_demographics bhdemo ON ws.ws_bill_hdemo_sk = bhdemo.hd_demo_sk
    JOIN customer scust ON ws.ws_ship_customer_sk = scust.c_customer_sk
    JOIN household_demographics shdemo ON ws.ws_ship_hdemo_sk = shdemo.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer pcust ON wp.wp_customer_sk = pcust.c_customer_sk
    JOIN household_demographics chdemo ON pcust.c_current_hdemo_sk = chdemo.hd_demo_sk
    CROSS JOIN (VALUES 1, 2, 3) AS t(tier)
GROUP BY
    i.i_manufact,
    i.i_category,
    chdemo.hd_income_band_sk,
    t.tier
ORDER BY
    total_sales DESC,
    i.i_manufact,
    t.tier
LIMIT 100
