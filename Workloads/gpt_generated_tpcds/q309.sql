WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT
    d.d_year,
    d.d_month_seq,
    p.p_promo_name,
    cp.cp_type,
    SUM(s.cs_ext_sales_price) AS total_sales,
    SUM(r.cr_return_amount) AS total_returns,
    SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_net_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT s.cs_item_sk) AS distinct_items_sold,
    SUM(s.cs_quantity) AS total_quantity_sold,
    AVG(s.cs_ext_discount_amt) AS avg_discount_amount
FROM sales s
JOIN catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON s.cs_promo_sk = p.p_promo_sk
JOIN date_dim d
    ON s.cs_sold_date_sk = d.d_date_sk
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
    AND s.cs_item_sk = r.cr_item_sk
WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY d.d_year, d.d_month_seq, p.p_promo_name, cp.cp_type
ORDER BY d.d_year, d.d_month_seq, total_sales DESC
