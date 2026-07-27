/*
Goal: Analyze store sales performance by state, year, catalog department, and website class, focusing on recent quarter activity and high‑value transactions.
The query joins the fact table store_sales with date_dim, store, catalog_page, and web_site using the allowed surrogate‑key relationships. It applies four selective filters (current quarter, specific county, department, and website class) and aggregates financial metrics, then filters groups with HAVING and orders by total net paid.
*/
WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_ext_sales_price
    FROM store_sales ss
    WHERE ss.ss_net_profit > 1000
      AND ss.ss_quantity > 5
)
SELECT
    s.s_state,
    d.d_year,
    cp.cp_department,
    w.web_class,
    SUM(fs.ss_net_paid) AS total_net_paid,
    AVG(fs.ss_net_profit) AS avg_net_profit,
    COUNT(*) AS sales_transactions,
    MIN(fs.ss_ext_sales_price) AS min_ext_sales_price,
    MAX(fs.ss_ext_sales_price) AS max_ext_sales_price
FROM filtered_sales fs
JOIN date_dim d
    ON fs.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON fs.ss_store_sk = s.s_store_sk
JOIN catalog_page cp
    ON d.d_date_sk = cp.cp_start_date_sk
JOIN web_site w
    ON d.d_date_sk = w.web_open_date_sk
WHERE d.d_current_quarter = 'Y'
  AND s.s_county = 'Mobile County'
  AND cp.cp_department = 'DEPARTMENT'
  AND w.web_class = 'E-Commerce'
GROUP BY s.s_state, d.d_year, cp.cp_department, w.web_class
HAVING SUM(fs.ss_net_paid) > 100000
   AND AVG(fs.ss_net_profit) > 500
ORDER BY total_net_paid DESC
LIMIT 100
