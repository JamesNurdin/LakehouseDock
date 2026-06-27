WITH sales_agg AS (
    SELECT
        cc.cc_name,
        cp.cp_catalog_page_id,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 1999
    GROUP BY cc.cc_name, cp.cp_catalog_page_id, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        cc.cc_name,
        cp.cp_catalog_page_id,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_net_loss) AS total_returns_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 1999
    GROUP BY cc.cc_name, cp.cp_catalog_page_id, d.d_year, d.d_month_seq
)
SELECT
    s.cc_name,
    s.cp_catalog_page_id,
    s.d_year,
    s.d_month_seq,
    s.total_sales_profit,
    COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
    s.total_sales_profit - COALESCE(r.total_returns_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cc_name = r.cc_name
    AND s.cp_catalog_page_id = r.cp_catalog_page_id
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
ORDER BY s.d_year, s.d_month_seq, net_profit_after_returns DESC
