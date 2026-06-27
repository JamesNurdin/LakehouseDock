WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_hdemo_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_order_number, cr.cr_item_sk
),
sales_with_dates AS (
    SELECT
        s.cs_order_number,
        s.cs_item_sk,
        s.cs_quantity,
        s.cs_net_paid,
        s.cs_ext_discount_amt,
        s.cs_promo_sk,
        s.cs_ship_mode_sk,
        s.cs_catalog_page_sk,
        s.cs_bill_hdemo_sk,
        d.d_year,
        d.d_month_seq
    FROM sales s
    JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    swd.d_year,
    swd.d_month_seq,
    hd.hd_buy_potential,
    p.p_promo_name,
    sm.sm_type,
    cp.cp_department,
    SUM(swd.cs_quantity) AS total_quantity,
    SUM(swd.cs_net_paid) AS total_sales,
    COALESCE(SUM(r.return_amount), 0) AS total_returns,
    SUM(swd.cs_net_paid) - COALESCE(SUM(r.return_amount), 0) AS net_revenue,
    AVG(swd.cs_ext_discount_amt) AS avg_discount_amount
FROM sales_with_dates swd
LEFT JOIN returns r
    ON swd.cs_order_number = r.cr_order_number
    AND swd.cs_item_sk = r.cr_item_sk
JOIN promotion p ON swd.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON swd.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp ON swd.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN household_demographics hd ON swd.cs_bill_hdemo_sk = hd.hd_demo_sk
GROUP BY
    swd.d_year,
    swd.d_month_seq,
    hd.hd_buy_potential,
    p.p_promo_name,
    sm.sm_type,
    cp.cp_department
ORDER BY
    net_revenue DESC
LIMIT 100
