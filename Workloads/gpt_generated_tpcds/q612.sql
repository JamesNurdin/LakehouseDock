WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_promo_sk,
        i.i_category,
        i.i_brand,
        d.d_year,
        d.d_month_seq,
        p.p_promo_name,
        p.p_discount_active
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2020
      AND p.p_discount_active = 'Y'
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim dr
        ON cr.cr_returned_date_sk = dr.d_date_sk
    WHERE dr.d_year = 2020
)
SELECT
    s.i_category,
    s.i_brand,
    s.p_promo_name,
    s.d_year,
    s.d_month_seq,
    SUM(s.cs_quantity) AS total_quantity_sold,
    SUM(s.cs_net_paid) AS total_net_paid,
    SUM(s.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(r.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(r.cr_net_loss), 0) AS total_return_loss,
    SUM(s.cs_net_paid) - COALESCE(SUM(r.cr_return_amount), 0) AS net_revenue_after_returns,
    SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_net_loss), 0) AS net_profit_after_returns
FROM sales s
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
   AND s.cs_item_sk = r.cr_item_sk
GROUP BY
    s.i_category,
    s.i_brand,
    s.p_promo_name,
    s.d_year,
    s.d_month_seq
ORDER BY
    s.d_year,
    s.d_month_seq,
    net_revenue_after_returns DESC
