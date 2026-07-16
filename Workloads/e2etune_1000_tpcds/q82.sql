WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        cp.cp_department AS department,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cp.cp_type = 'monthly'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy, cp.cp_department
),
store_ret_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        COUNT(*) AS store_ret_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy
),
web_ret_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        COUNT(*) AS web_ret_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy
)
SELECT
    s.d_year,
    s.d_moy,
    s.department,
    s.total_net_paid,
    s.total_net_profit,
    COALESCE(sr.total_store_return_amt, 0) AS store_return_amt,
    COALESCE(wr.total_web_return_amt, 0) AS web_return_amt,
    (s.total_net_profit - COALESCE(sr.total_store_return_amt, 0) - COALESCE(wr.total_web_return_amt, 0)) AS net_profit_after_returns,
    ROUND(
        CASE WHEN s.total_net_paid = 0 THEN 0
        ELSE (s.total_net_profit - COALESCE(sr.total_store_return_amt, 0) - COALESCE(wr.total_web_return_amt, 0)) / s.total_net_paid * 100
        END, 2
    ) AS profit_margin_pct
FROM sales_agg s
LEFT JOIN store_ret_agg sr
    ON s.d_year = sr.d_year AND s.d_moy = sr.d_moy
LEFT JOIN web_ret_agg wr
    ON s.d_year = wr.d_year AND s.d_moy = wr.d_moy
ORDER BY s.d_year, s.d_moy, s.department
