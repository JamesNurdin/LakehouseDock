WITH union_sales AS (
    SELECT
        d.d_year,
        w.web_company_name,
        CASE WHEN s.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        s.ws_ext_sales_price,
        s.ws_net_profit
    FROM (
        SELECT * FROM tpcds.web_sales TABLESAMPLE BERNOULLI (10)
    ) s
    JOIN tpcds.date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_site w ON s.ws_web_site_sk = w.web_site_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND w.web_state = 'CA'
      AND s.ws_wholesale_cost > 20
      AND s.ws_ext_tax < 100
      AND s.ws_wholesale_cost > 50
    UNION DISTINCT
    SELECT
        d.d_year,
        w.web_company_name,
        CASE WHEN s.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        s.ws_ext_sales_price,
        s.ws_net_profit
    FROM (
        SELECT * FROM tpcds.web_sales TABLESAMPLE BERNOULLI (10)
    ) s
    JOIN tpcds.date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_site w ON s.ws_web_site_sk = w.web_site_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND w.web_state = 'CA'
      AND s.ws_wholesale_cost > 20
      AND s.ws_ext_tax < 100
      AND s.ws_wholesale_cost <= 50
),
agg_sales AS (
    SELECT
        d_year,
        web_company_name,
        profit_flag,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM union_sales
    GROUP BY ROLLUP (d_year, web_company_name, profit_flag)
),
final_agg AS (
    SELECT
        d_year,
        AVG(total_profit) AS avg_profit,
        SUM(total_sales) AS sum_sales
    FROM agg_sales
    WHERE d_year IS NOT NULL
    GROUP BY ROLLUP (d_year)
)
SELECT
    d_year,
    avg_profit,
    sum_sales,
    sum_sales / NULLIF(avg_profit, 0) AS sales_to_avg_profit_ratio
FROM final_agg
ORDER BY d_year DESC
LIMIT 100
