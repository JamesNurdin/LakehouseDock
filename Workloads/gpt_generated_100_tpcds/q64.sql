WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_order_number,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    i.i_category,
    p.p_promo_name,
    cc.cc_name,
    sum(s.cs_quantity) AS total_quantity_sold,
    sum(s.cs_net_paid) AS total_net_paid,
    sum(s.cs_net_profit) AS total_net_profit,
    avg(s.cs_ext_discount_amt) AS avg_discount_amount,
    sum(r.cr_return_quantity) AS total_quantity_returned,
    sum(r.cr_net_loss) AS total_return_net_loss,
    (sum(s.cs_net_profit) - coalesce(sum(r.cr_net_loss), 0)) AS net_profit_after_returns,
    count(distinct s.cs_bill_customer_sk) AS distinct_customers
FROM sales s
JOIN date_dim d_sales ON s.cs_sold_date_sk = d_sales.d_date_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
   AND s.cs_item_sk = r.cr_item_sk
WHERE d_sales.d_year = 2001
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    i.i_category,
    p.p_promo_name,
    cc.cc_name
ORDER BY
    d_sales.d_year,
    d_sales.d_month_seq,
    i.i_category,
    net_profit_after_returns DESC
