/* goal: Identify top-performing web sites (starting with 'A' and containing 'Shop') by yearly sales, showing profit categories, average site sales, a cumulative sales window, and ranking, while applying string filters on URLs and customer emails */
WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        d.d_year,
        ws.ws_ext_sales_price AS sales_price,
        ws.ws_net_profit AS profit,
        ws.ws_bill_customer_sk,
        wp.wp_url,
        c.c_email_address
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(w.web_name, '^A.*')
      AND w.web_name LIKE '%Shop%'
      AND regexp_like(wp.wp_url, 'product')
      AND c.c_email_address LIKE '%@gmail.com%'
)
SELECT
    w.web_name,
    w.web_company_name,
    s.d_year,
    CONCAT(w.web_name, ' - ', CAST(s.d_year AS VARCHAR)) AS site_year,
    SUM(s.sales_price) AS total_sales,
    SUM(s.profit) AS total_profit,
    CASE WHEN SUM(s.profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    (
        SELECT AVG(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = s.ws_web_site_sk
    ) AS avg_site_sales,
    ROW_NUMBER() OVER (PARTITION BY w.web_name ORDER BY SUM(s.sales_price) DESC) AS rn,
    SUM(SUM(s.sales_price)) OVER (PARTITION BY w.web_name ORDER BY s.d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM sales_agg s
JOIN web_site w ON s.ws_web_site_sk = w.web_site_sk
GROUP BY w.web_name, w.web_company_name, s.d_year, s.ws_web_site_sk
ORDER BY total_sales DESC
LIMIT 100
