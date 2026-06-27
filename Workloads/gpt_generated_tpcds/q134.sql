WITH sales_with_site AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        d.d_year,
        d.d_moy,
        ws_site.web_name
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN date_dim open_d
        ON ws_site.web_open_date_sk = open_d.d_date_sk
    LEFT JOIN date_dim close_d
        ON ws_site.web_close_date_sk = close_d.d_date_sk
    WHERE d.d_date >= open_d.d_date
      AND (close_d.d_date IS NULL OR d.d_date <= close_d.d_date)
)
SELECT
    web_name,
    d_year,
    d_moy AS month_of_year,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_ext_discount_amt) AS total_discount,
    SUM(ws_net_profit) AS total_profit,
    AVG(ws_ext_discount_amt / NULLIF(ws_ext_sales_price, 0)) AS avg_discount_rate
FROM sales_with_site
GROUP BY web_name, d_year, d_moy
ORDER BY web_name, d_year, d_moy
