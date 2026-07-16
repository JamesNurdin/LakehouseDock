WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cc.cc_name,
        cp.cp_department,
        p.p_promo_id,
        d.d_year,
        d.d_moy,
        d.d_date
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_returned_date_sk,
        rd.d_year AS return_year,
        rd.d_moy AS return_month,
        rd.d_date AS return_date
    FROM catalog_returns cr
    JOIN date_dim rd ON cr.cr_returned_date_sk = rd.d_date_sk
    WHERE rd.d_date >= DATE '2001-01-01'
      AND rd.d_date < DATE '2002-01-01'
)
SELECT
    s.d_year,
    s.d_moy,
    date_trunc('month', s.d_date) AS month_start,
    s.cc_name,
    s.p_promo_id,
    SUM(s.cs_net_paid) AS total_sales,
    SUM(s.cs_net_profit) AS total_profit,
    COUNT(DISTINCT s.cs_order_number) AS distinct_orders,
    COALESCE(SUM(r.cr_return_amount), 0) AS total_returns,
    SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_return_amount), 0) AS profit_after_returns
FROM sales s
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
   AND s.cs_item_sk = r.cr_item_sk
GROUP BY
    s.d_year,
    s.d_moy,
    date_trunc('month', s.d_date),
    s.cc_name,
    s.p_promo_id
ORDER BY
    s.d_year,
    s.d_moy,
    s.cc_name,
    s.p_promo_id
