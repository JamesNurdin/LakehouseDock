WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_tax_percentage,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_tax_percentage, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        cc.cc_call_center_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cc.cc_call_center_sk, d.d_year, d.d_month_seq
),
websites_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT ws.web_site_sk) AS websites_opened
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    s.cc_name,
    s.cc_tax_percentage,
    s.d_year,
    s.d_month_seq,
    s.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.distinct_items_sold,
    COALESCE(w.websites_opened, 0) AS websites_opened
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cc_call_center_sk = r.cc_call_center_sk
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
LEFT JOIN websites_agg w
    ON s.d_year = w.d_year
    AND s.d_month_seq = w.d_month_seq
ORDER BY s.d_year, s.d_month_seq, s.cc_name
