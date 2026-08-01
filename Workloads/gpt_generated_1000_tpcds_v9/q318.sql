WITH first AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        CASE WHEN regexp_like(p.p_promo_name, '^.*20[0-9]{2}.*$') THEN 'HAS_20xx' ELSE 'OTHER' END AS promo_flag,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_number,
        CONCAT(p.p_promo_name, '_', CAST(cs.cs_order_number AS varchar)) AS extra_info
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    FULL OUTER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_promo_name LIKE '%Discount%'
      AND cs.cs_quantity > (
          SELECT CAST(AVG(ws_quantity) AS integer)
          FROM web_sales
      )
),
second AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        CASE WHEN regexp_like(p.p_promo_name, '^.*20[0-9]{2}.*$') THEN 'HAS_20xx' ELSE 'OTHER' END AS promo_flag,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_number,
        SUBSTRING(p.p_promo_name, 1, 5) AS extra_info
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_promo_name LIKE '%Discount%'
),
unioned AS (
    SELECT date_sk, promo_flag, quantity, net_paid, net_profit, promo_number, extra_info FROM first
    UNION
    SELECT date_sk, promo_flag, quantity, net_paid, net_profit, promo_number, extra_info FROM second
)
SELECT
    date_sk,
    promo_flag,
    SUM(quantity) AS total_quantity,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit
FROM unioned
GROUP BY GROUPING SETS (
    (date_sk, promo_flag),
    (date_sk),
    (promo_flag),
    ()
)
ORDER BY date_sk NULLS LAST, promo_flag
LIMIT 100
