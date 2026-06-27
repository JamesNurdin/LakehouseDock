WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT
    d_sold.d_year AS year,
    i.i_category AS category,
    cc.cc_name AS call_center_name,
    SUM(s.cs_net_paid) AS total_sales,
    SUM(s.cs_net_profit) AS total_profit,
    SUM(r.cr_net_loss) AS total_returns,
    SUM(s.cs_net_paid) - COALESCE(SUM(r.cr_net_loss), 0) AS net_revenue,
    SUM(s.cs_ext_discount_amt) / NULLIF(SUM(s.cs_quantity), 0) AS avg_discount_per_unit
FROM sales s
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
JOIN date_dim d_sold
    ON s.cs_sold_date_sk = d_sold.d_date_sk
JOIN item i
    ON s.cs_item_sk = i.i_item_sk
JOIN call_center cc
    ON s.cs_call_center_sk = cc.cc_call_center_sk
WHERE d_sold.d_year = 2001
GROUP BY d_sold.d_year, i.i_category, cc.cc_name
ORDER BY net_revenue DESC
LIMIT 10
