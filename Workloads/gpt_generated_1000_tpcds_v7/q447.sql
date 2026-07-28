WITH catalog_promo AS (
    SELECT
        p.p_promo_id AS promo_id,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        SUM(cs.cs_ext_discount_amt) AS total_discount
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id
),
web_promo AS (
    SELECT
        p.p_promo_id AS promo_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id
)
SELECT
    cp.promo_id,
    cp.total_profit,
    cp.sales_cnt
FROM catalog_promo cp
WHERE cp.total_discount > (
    SELECT AVG(total_discount) FROM catalog_promo
)
UNION ALL
SELECT
    wp.promo_id,
    wp.total_profit,
    wp.sales_cnt
FROM web_promo wp
WHERE EXISTS (
    SELECT 1
    FROM catalog_promo cp
    WHERE cp.promo_id = wp.promo_id
      AND cp.total_profit > wp.total_profit
)
