SELECT DISTINCT sales_year,
                site_name,
                total_sales,
                profit_flag
FROM (
        SELECT d.d_year AS sales_year,
               ws.web_name AS site_name,
               SUM(ws_sales.ws_ext_sales_price) AS total_sales,
               CASE WHEN SUM(ws_sales.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
        FROM web_sales ws_sales
        JOIN date_dim d ON ws_sales.ws_sold_date_sk = d.d_date_sk
        JOIN web_site ws ON ws_sales.ws_web_site_sk = ws.web_site_sk
        WHERE ws.web_company_id = 3
          AND d.d_year BETWEEN 2000 AND 2002
        GROUP BY d.d_year, ws.web_name
        UNION ALL
        SELECT d.d_year AS sales_year,
               w.w_warehouse_name AS site_name,
               SUM(ws_sales.ws_ext_sales_price) AS total_sales,
               CASE WHEN SUM(ws_sales.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
        FROM web_sales ws_sales
        JOIN date_dim d ON ws_sales.ws_ship_date_sk = d.d_date_sk
        JOIN warehouse w ON ws_sales.ws_warehouse_sk = w.w_warehouse_sk
        WHERE w.w_state = 'CA'
          AND d.d_year BETWEEN 2000 AND 2002
        GROUP BY d.d_year, w.w_warehouse_name
) AS combined
ORDER BY total_sales DESC
LIMIT 100
