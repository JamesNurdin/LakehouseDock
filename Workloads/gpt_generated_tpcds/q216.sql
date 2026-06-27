WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_promo_sk,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_order_number
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
)
SELECT
    ds.d_year,
    ds.d_month_seq,
    p.p_channel_email,
    i.i_category,
    sum(s.cs_net_profit) AS total_net_profit,
    sum(s.cs_net_paid) AS total_net_paid,
    avg(s.cs_ext_discount_amt) AS avg_discount_amt,
    coalesce(sum(r.cr_return_quantity), 0) AS total_return_qty,
    coalesce(sum(r.cr_net_loss), 0) AS total_return_loss
FROM sales s
JOIN date_dim ds ON s.cs_sold_date_sk = ds.d_date_sk
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
LEFT JOIN returns r ON s.cs_order_number = r.cr_order_number
LEFT JOIN date_dim dr ON r.cr_returned_date_sk = dr.d_date_sk
WHERE ds.d_year = 2000
GROUP BY ds.d_year, ds.d_month_seq, p.p_channel_email, i.i_category
ORDER BY ds.d_year, ds.d_month_seq, p.p_channel_email, i.i_category
