WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cs.cs_call_center_sk,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category, cs.cs_call_center_sk
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cr.cr_call_center_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category, cr.cr_call_center_sk
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    cc.cc_name,
    s.sales_cnt,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    s.total_sales,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.i_category = r.i_category
   AND s.cs_call_center_sk = r.cr_call_center_sk
JOIN call_center cc
    ON s.cs_call_center_sk = cc.cc_call_center_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100
