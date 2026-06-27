WITH profit_by_cc AS (
    SELECT
        d_sales.d_year AS sales_year,
        i.i_category AS product_category,
        cc.cc_name AS call_center_name,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales_inc_tax,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
        (SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) AS net_profit_after_returns
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE d_sales.d_year BETWEEN 2001 AND 2002
    GROUP BY d_sales.d_year, i.i_category, cc.cc_name
)
SELECT
    sales_year,
    product_category,
    call_center_name,
    total_sales_inc_tax,
    total_sales_profit,
    total_return_amount,
    total_return_loss,
    net_profit_after_returns,
    ROW_NUMBER() OVER (PARTITION BY sales_year, product_category ORDER BY net_profit_after_returns DESC) AS rank_within_category
FROM profit_by_cc
ORDER BY sales_year, product_category, rank_within_category
LIMIT 100
