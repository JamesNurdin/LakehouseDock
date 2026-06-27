WITH sales_agg AS (
    SELECT
        cc.cc_name,
        d_sales.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
        SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) AS net_profit_after_returns,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(COALESCE(cr.cr_return_amount, 0)) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS return_rate
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN date_dim d_returns
        ON cr.cr_returned_date_sk = d_returns.d_date_sk
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    LEFT JOIN date_dim d_close
        ON cc.cc_closed_date_sk = d_close.d_date_sk
    WHERE d_sales.d_year = 2001
      AND d_sales.d_date >= d_open.d_date
      AND (d_close.d_date IS NULL OR d_sales.d_date <= d_close.d_date)
    GROUP BY cc.cc_name, d_sales.d_year
)
SELECT
    cc_name,
    d_year,
    total_sales,
    total_returns,
    net_profit_after_returns,
    avg_discount,
    return_rate
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 10
