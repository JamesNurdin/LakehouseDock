SELECT combined.d_year,
       combined.i_category,
       combined.channel,
       combined.total_sales
FROM (
    SELECT d.d_year,
           i.i_category,
           CAST('Store' AS varchar) AS channel,
           SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND s.s_state = 'CA'
    GROUP BY d.d_year, i.i_category
    HAVING SUM(ss.ss_ext_sales_price) > 10000
    UNION ALL
    SELECT d.d_year,
           i.i_category,
           CAST('Web' AS varchar) AS channel,
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND wp.wp_type = 'Home'
    GROUP BY d.d_year, i.i_category
    HAVING SUM(ws.ws_ext_sales_price) > 10000
) AS combined
ORDER BY combined.total_sales DESC
LIMIT 100
