WITH store_sales_agg AS (
    SELECT
        p.p_promo_id   AS promo_id,
        p.p_promo_name AS promo_name,
        d.d_year,
        d.d_moy,
        SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY p.p_promo_id, p.p_promo_name, d.d_year, d.d_moy
),
catalog_sales_agg AS (
    SELECT
        p.p_promo_id   AS promo_id,
        p.p_promo_name AS promo_name,
        d.d_year,
        d.d_moy,
        SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d   ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY p.p_promo_id, p.p_promo_name, d.d_year, d.d_moy
),
web_sales_agg AS (
    SELECT
        p.p_promo_id   AS promo_id,
        p.p_promo_name AS promo_name,
        d.d_year,
        d.d_moy,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d   ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY p.p_promo_id, p.p_promo_name, d.d_year, d.d_moy
),
combined AS (
    SELECT promo_id, promo_name, d_year, d_moy, net_profit FROM store_sales_agg
    UNION ALL
    SELECT promo_id, promo_name, d_year, d_moy, net_profit FROM catalog_sales_agg
    UNION ALL
    SELECT promo_id, promo_name, d_year, d_moy, net_profit FROM web_sales_agg
)
SELECT
    promo_id,
    promo_name,
    d_year,
    d_moy,
    SUM(net_profit) AS total_net_profit
FROM combined
GROUP BY promo_id, promo_name, d_year, d_moy
ORDER BY total_net_profit DESC
LIMIT 100
