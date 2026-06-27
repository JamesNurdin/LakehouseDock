WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        d.d_year,
        d.d_moy,
        i.i_category,
        cc.cc_name
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_net_loss,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        d_ret.d_year,
        d_ret.d_moy,
        i_ret.i_category
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i_ret
        ON cr.cr_item_sk = i_ret.i_item_sk
    JOIN call_center cc_ret
        ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
    WHERE d_ret.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
)
SELECT
    s.d_year,
    s.d_moy,
    s.i_category,
    s.cc_name,
    SUM(s.cs_net_profit) AS total_sales_net_profit,
    SUM(r.cr_net_loss) AS total_returns_net_loss,
    SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_net_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT s.cs_order_number) AS distinct_sales_orders,
    COUNT(DISTINCT r.cr_order_number) AS distinct_return_orders
FROM sales s
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
    AND s.cs_item_sk = r.cr_item_sk
GROUP BY
    s.d_year,
    s.d_moy,
    s.i_category,
    s.cc_name
ORDER BY
    s.d_year,
    s.d_moy,
    s.i_category,
    s.cc_name
