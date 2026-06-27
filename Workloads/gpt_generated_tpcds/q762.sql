WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk AS call_center_sk,
        cc.cc_name,
        d_sales.d_year,
        d_sales.d_month_seq,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d_sales.d_year = 2001
    GROUP BY cc.cc_call_center_sk, cc.cc_name, d_sales.d_year, d_sales.d_month_seq
),
returns_agg AS (
    SELECT
        cc.cc_call_center_sk AS call_center_sk,
        cc.cc_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d_ret.d_year = 2001
    GROUP BY cc.cc_call_center_sk, cc.cc_name, d_ret.d_year, d_ret.d_month_seq
)
SELECT
    s.cc_name,
    s.d_year,
    s.d_month_seq,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.total_quantity - COALESCE(r.total_return_quantity, 0) AS net_quantity_sold
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.call_center_sk = r.call_center_sk
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
ORDER BY s.cc_name, s.d_year, s.d_month_seq
