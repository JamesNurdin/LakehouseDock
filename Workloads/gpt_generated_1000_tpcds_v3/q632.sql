WITH catalog_sales_agg AS (
    SELECT DISTINCT
        d.d_date AS sale_date,
        p.p_promo_id AS promo_id,
        cs.cs_net_paid_inc_ship_tax AS net_amount,
        CASE
            WHEN cs.cs_net_paid_inc_ship_tax >= 10000 THEN 'High'
            WHEN cs.cs_net_paid_inc_ship_tax >= 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
),
web_sales_agg AS (
    SELECT DISTINCT
        d.d_date AS sale_date,
        p.p_promo_id AS promo_id,
        ws.ws_net_paid_inc_ship_tax AS net_amount,
        CASE
            WHEN ws.ws_net_paid_inc_ship_tax >= 10000 THEN 'High'
            WHEN ws.ws_net_paid_inc_ship_tax >= 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
),
combined_sales AS (
    SELECT sale_date, promo_id, net_amount, profit_category FROM catalog_sales_agg
    UNION ALL
    SELECT sale_date, promo_id, net_amount, profit_category FROM web_sales_agg
)
SELECT
    sale_date,
    promo_id,
    profit_category,
    SUM(net_amount) AS total_net_amount
FROM combined_sales
GROUP BY sale_date, promo_id, profit_category
ORDER BY total_net_amount DESC
LIMIT 100
