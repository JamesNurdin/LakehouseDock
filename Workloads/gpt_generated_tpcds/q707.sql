WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_item_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    cc.cc_name,
    SUM(s.cs_net_profit) AS total_net_profit,
    SUM(COALESCE(r.cr_return_amount, 0)) AS total_return_amount,
    SUM(s.cs_net_profit) - SUM(COALESCE(r.cr_return_amount, 0)) AS net_profit_after_returns,
    COUNT(DISTINCT s.cs_order_number) AS num_orders,
    COUNT(DISTINCT r.cr_order_number) AS num_returns
FROM sales s
JOIN date_dim d_sold
    ON s.cs_sold_date_sk = d_sold.d_date_sk
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
LEFT JOIN date_dim d_ret
    ON r.cr_returned_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON s.cs_promo_sk = p.p_promo_sk
JOIN call_center cc
    ON s.cs_call_center_sk = cc.cc_call_center_sk
WHERE d_sold.d_date >= DATE '2000-01-01'
  AND d_sold.d_date <= DATE '2000-12-31'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    cc.cc_name
ORDER BY
    d_sold.d_year,
    d_sold.d_month_seq,
    total_net_profit DESC
