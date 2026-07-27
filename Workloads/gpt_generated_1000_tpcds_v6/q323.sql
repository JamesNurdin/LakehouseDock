SELECT year,
       sales_type,
       total_sales
FROM (
    SELECT d.d_year AS year,
           'sold' AS sales_type,
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_units = 'Case'
      AND ws.ws_list_price > 50
    GROUP BY d.d_year
    UNION ALL
    SELECT d.d_year AS year,
           'shipped' AS sales_type,
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_units = 'Pound'
      AND ws.ws_list_price > 50
    GROUP BY d.d_year
) AS combined
ORDER BY year, sales_type
LIMIT 100
