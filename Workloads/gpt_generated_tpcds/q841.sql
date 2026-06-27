WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_amount
    FROM catalog_returns cr
)
SELECT
    d.d_year,
    d.d_month_seq,
    p.p_promo_name,
    i.i_category,
    cc.cc_name,
    sm.sm_type,
    SUM(s.cs_net_paid) AS total_sales,
    SUM(s.cs_quantity) AS total_quantity,
    SUM(r.cr_return_amount) AS total_returns,
    SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_return_amount), 0) AS net_profit,
    ROUND(
        (SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_return_amount), 0)) / NULLIF(SUM(s.cs_net_paid), 0) * 100,
        2
    ) AS profit_margin_pct
FROM sales s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN returns r ON s.cs_order_number = r.cr_order_number AND s.cs_item_sk = r.cr_item_sk
WHERE d.d_date >= DATE '2020-01-01' AND d.d_date < DATE '2021-01-01'
GROUP BY d.d_year, d.d_month_seq, p.p_promo_name, i.i_category, cc.cc_name, sm.sm_type
ORDER BY total_sales DESC
LIMIT 100
