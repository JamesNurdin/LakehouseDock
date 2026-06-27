WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
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
    i.i_category,
    COALESCE(p.p_promo_name, 'No Promotion') AS promotion_name,
    SUM(s.cs_ext_sales_price) AS total_sales,
    SUM(s.cs_ext_discount_amt) AS total_discount,
    SUM(s.cs_net_profit) AS total_profit,
    SUM(COALESCE(r.cr_return_amount, 0)) AS total_returns,
    SUM(COALESCE(r.cr_net_loss, 0)) AS total_return_loss,
    SUM(s.cs_ext_sales_price) - SUM(COALESCE(r.cr_return_amount, 0)) AS net_sales,
    SUM(s.cs_net_profit) - SUM(COALESCE(r.cr_net_loss, 0)) AS net_profit
FROM sales s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
    AND s.cs_item_sk = r.cr_item_sk
WHERE d.d_year = 2001
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_category,
    COALESCE(p.p_promo_name, 'No Promotion')
ORDER BY
    d.d_year,
    d.d_month_seq,
    i.i_category,
    net_sales DESC
