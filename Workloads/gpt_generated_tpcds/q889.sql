WITH sales_agg AS (
    SELECT
        cc.cc_name,
        d_sales.d_year,
        d_sales.d_moy,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d_sales.d_year = 2001
    GROUP BY cc.cc_name, d_sales.d_year, d_sales.d_moy
),
returns_agg AS (
    SELECT
        cc.cc_name,
        d_returns.d_year,
        d_returns.d_moy,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_quantity_returned
    FROM catalog_returns cr
    JOIN date_dim d_returns
        ON cr.cr_returned_date_sk = d_returns.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d_returns.d_year = 2001
    GROUP BY cc.cc_name, d_returns.d_year, d_returns.d_moy
)
SELECT
    COALESCE(s.cc_name, r.cc_name) AS call_center_name,
    COALESCE(s.d_year, r.d_year) AS year,
    COALESCE(s.d_moy, r.d_moy) AS month,
    s.total_sales_profit,
    r.total_return_loss,
    s.total_sales_profit - r.total_return_loss AS net_profit_after_returns,
    s.total_sales_amount,
    r.total_quantity_returned
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.cc_name = r.cc_name
   AND s.d_year = r.d_year
   AND s.d_moy = r.d_moy
ORDER BY year, month, call_center_name
