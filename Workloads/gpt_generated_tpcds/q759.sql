WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_ship_cost,
        cs.cs_promo_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    GROUP BY cr.cr_order_number
)
SELECT
    cc.cc_name,
    d.d_year,
    d.d_moy,
    SUM(s.cs_net_paid) AS total_net_paid,
    SUM(s.cs_net_profit) AS total_net_profit,
    SUM(s.cs_ext_ship_cost) AS total_ship_cost,
    COUNT(DISTINCT s.cs_order_number) AS total_orders,
    COUNT(DISTINCT CASE WHEN s.cs_promo_sk IS NOT NULL THEN s.cs_order_number END) AS promo_orders,
    (COUNT(DISTINCT CASE WHEN s.cs_promo_sk IS NOT NULL THEN s.cs_order_number END) / NULLIF(COUNT(DISTINCT s.cs_order_number), 0)) * 100 AS promo_rate_percent,
    SUM(COALESCE(r.total_return_amount, 0)) AS total_return_amount,
    (SUM(COALESCE(r.total_return_amount, 0)) / NULLIF(SUM(s.cs_net_paid), 0)) * 100 AS return_rate_percent
FROM sales s
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
LEFT JOIN returns r ON s.cs_order_number = r.cr_order_number
WHERE d.d_year = 2001
GROUP BY cc.cc_name, d.d_year, d.d_moy
ORDER BY total_net_paid DESC
LIMIT 10
