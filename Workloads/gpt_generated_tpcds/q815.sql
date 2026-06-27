-- Net profit and return analysis by year, call‑center state and item category for active promotions
WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        d.d_year,
        i.i_category,
        cc.cc_state,
        p.p_discount_active
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
      AND p.p_discount_active = 'Y'
), returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT
    s.d_year,
    s.cc_state,
    s.i_category,
    SUM(s.cs_quantity) AS total_quantity_sold,
    SUM(s.cs_ext_sales_price) AS total_sales_amount,
    SUM(s.cs_ext_discount_amt) AS total_discount_amount,
    SUM(s.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(r.cr_return_quantity), 0) AS total_quantity_returned,
    COALESCE(SUM(r.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(r.cr_net_loss), 0) AS total_return_loss,
    CASE WHEN SUM(s.cs_ext_sales_price) = 0 THEN 0
         ELSE (COALESCE(SUM(r.cr_return_amount), 0) / SUM(s.cs_ext_sales_price))
    END AS return_rate
FROM sales s
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
   AND s.cs_item_sk = r.cr_item_sk
GROUP BY s.d_year, s.cc_state, s.i_category
ORDER BY s.d_year DESC, total_net_profit DESC
LIMIT 100
