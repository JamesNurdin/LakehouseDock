WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk AS call_center_sk,
        cc.cc_name AS call_center_name,
        cp.cp_department AS department,
        d.d_year,
        d.d_moy,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales_net_paid,
        SUM(cs.cs_net_profit) AS total_sales_net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cc.cc_call_center_sk, cc.cc_name, cp.cp_department, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        cc.cc_call_center_sk AS call_center_sk,
        cc.cc_name AS call_center_name,
        cp.cp_department AS department,
        d.d_year,
        d.d_moy,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_net_loss
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cc.cc_call_center_sk, cc.cc_name, cp.cp_department, d.d_year, d.d_moy
)
SELECT
    s.call_center_name,
    s.department,
    s.d_year,
    s.d_moy,
    s.total_sales_net_paid,
    s.total_sales_net_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_net_loss, 0) AS total_return_net_loss,
    (s.total_sales_net_profit - COALESCE(r.total_return_net_loss, 0)) AS net_profit_after_returns,
    ROW_NUMBER() OVER (
        PARTITION BY s.call_center_name
        ORDER BY (s.total_sales_net_profit - COALESCE(r.total_return_net_loss, 0)) DESC
    ) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.call_center_sk = r.call_center_sk
   AND s.d_year = r.d_year
   AND s.d_moy = r.d_moy
   AND s.department = r.department
ORDER BY net_profit_after_returns DESC
LIMIT 100
