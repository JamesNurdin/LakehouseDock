WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_bill_customer_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_reason_sk
    FROM catalog_returns cr
)
SELECT
    d_sales.d_year,
    d_sales.d_moy,
    p.p_promo_name,
    i.i_category,
    sm.sm_type,
    sum(s.cs_net_profit) AS total_net_profit,
    sum(r.cr_net_loss) AS total_return_loss,
    sum(s.cs_quantity) AS total_quantity_sold,
    sum(r.cr_return_quantity) AS total_quantity_returned,
    (sum(r.cr_return_quantity) * 100.0 / nullif(sum(s.cs_quantity), 0)) AS return_rate_percent,
    avg(s.cs_ext_discount_amt) AS avg_discount_amount,
    count(distinct s.cs_bill_customer_sk) AS distinct_customers,
    count(distinct s.cs_item_sk) AS distinct_items
FROM sales s
JOIN date_dim d_sales ON s.cs_sold_date_sk = d_sales.d_date_sk
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN returns r ON s.cs_order_number = r.cr_order_number
LEFT JOIN date_dim d_returns ON r.cr_returned_date_sk = d_returns.d_date_sk
WHERE d_sales.d_year = 2001
GROUP BY
    d_sales.d_year,
    d_sales.d_moy,
    p.p_promo_name,
    i.i_category,
    sm.sm_type
ORDER BY total_net_profit DESC
LIMIT 100
