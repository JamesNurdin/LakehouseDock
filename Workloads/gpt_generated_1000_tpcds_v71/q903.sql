WITH ws_agg AS (
    SELECT
        ws_promo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS order_count,
        AVG(ws_ext_ship_cost) AS avg_ship_cost
    FROM tpcds.web_sales
    WHERE ws_ship_cdemo_sk IN (1630659, 601676, 1895897)
      AND ws_ext_ship_cost > 1000
      AND ws_quantity >= 2
    GROUP BY ws_promo_sk
),
promo_join AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_demo,
        p.p_channel_press,
        ws_agg.total_sales,
        ws_agg.total_discount,
        ws_agg.order_count,
        ws_agg.avg_ship_cost,
        (ws_agg.total_sales - ws_agg.total_discount) AS net_sales
    FROM tpcds.promotion p
    JOIN ws_agg
        ON p.p_promo_sk = ws_agg.ws_promo_sk
    WHERE p.p_channel_demo = 'N'
      AND p.p_channel_press = 'N'
      AND p.p_cost < 5000
)
SELECT
    pj.p_channel_demo,
    COUNT(*) AS promo_cnt,
    AVG(pj.total_sales) AS avg_total_sales,
    SUM(pj.net_sales) AS sum_net_sales,
    (
        SELECT MAX(p3.p_cost)
        FROM tpcds.promotion p3
        WHERE p3.p_channel_demo = pj.p_channel_demo
    ) AS max_cost_demo
FROM promo_join pj
GROUP BY pj.p_channel_demo
HAVING AVG(pj.total_sales) > 10000
ORDER BY sum_net_sales DESC
LIMIT 100
