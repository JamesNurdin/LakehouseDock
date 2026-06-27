WITH sales_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        d_sold.d_year AS year,
        d_sold.d_moy AS month,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2000
    GROUP BY cc.cc_name, d_sold.d_year, d_sold.d_moy
),
returns_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        d_ret.d_year AS year,
        d_ret.d_moy AS month,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2000
    GROUP BY cc.cc_name, d_ret.d_year, d_ret.d_moy
)
SELECT
    s.call_center_name,
    s.year,
    s.month,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.total_sales_amount,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_quantity,
    COALESCE(r.return_count, 0) AS return_count
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.call_center_name = r.call_center_name
    AND s.year = r.year
    AND s.month = r.month
ORDER BY s.year, s.month, s.call_center_name
