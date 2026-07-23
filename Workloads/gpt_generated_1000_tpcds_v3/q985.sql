WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        d.d_date,
        d.d_year,
        cs.cs_warehouse_sk,
        w.w_warehouse_name,
        cs.cs_net_profit,
        cs.cs_promo_sk,
        p.p_channel_tv,
        p.p_channel_email
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
)
SELECT
    w_warehouse_name,
    d_year,
    SUM(cs_net_profit) AS net_profit,
    'TV Promo 2022' AS promo_type
FROM sales_base
WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
  AND p_channel_tv = 'Y'
GROUP BY w_warehouse_name, d_year
UNION ALL
SELECT
    w_warehouse_name,
    d_year,
    SUM(cs_net_profit) AS net_profit,
    'Email Promo 2023' AS promo_type
FROM sales_base
WHERE d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
  AND p_channel_email = 'Y'
GROUP BY w_warehouse_name, d_year
ORDER BY w_warehouse_name, d_year, promo_type
