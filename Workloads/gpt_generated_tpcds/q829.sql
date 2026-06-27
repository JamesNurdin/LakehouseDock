WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
returns_agg AS (
    SELECT
        cr.cr_order_number,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_order_number
),
sales_with_date AS (
    SELECT
        s.cs_sold_date_sk,
        s.cs_item_sk,
        s.cs_order_number,
        s.cs_net_paid_inc_tax,
        s.cs_call_center_sk,
        s.cs_ship_mode_sk,
        d.d_year,
        d.d_month_seq
    FROM sales s
    JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
)
SELECT
    s.d_year,
    s.d_month_seq,
    cc.cc_name,
    sm.sm_type,
    SUM(s.cs_net_paid_inc_tax) AS total_sales,
    SUM(COALESCE(r.total_return_amount, 0)) AS total_returns,
    SUM(s.cs_net_paid_inc_tax) - SUM(COALESCE(r.total_return_amount, 0)) AS net_revenue
FROM sales_with_date s
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN returns_agg r ON s.cs_order_number = r.cr_order_number
GROUP BY s.d_year, s.d_month_seq, cc.cc_name, sm.sm_type
ORDER BY s.d_year, s.d_month_seq, cc.cc_name, sm.sm_type
