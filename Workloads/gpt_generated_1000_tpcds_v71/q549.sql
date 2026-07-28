WITH high_price_items AS (
    SELECT i_item_sk,
           i_category,
           i_current_price
    FROM tpcds.item
    WHERE i_current_price > 50
)
SELECT year,
       category,
       total_sales,
       channel,
       avg_price
FROM (
    SELECT d.d_year AS year,
           i.i_category AS category,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           'store' AS channel,
           (SELECT AVG(hpi.i_current_price)
            FROM high_price_items hpi
            WHERE hpi.i_category = i.i_category) AS avg_price
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
      ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_category IN (SELECT DISTINCT i_category FROM high_price_items)
    GROUP BY d.d_year, i.i_category

    UNION ALL

    SELECT d.d_year AS year,
           i.i_category AS category,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           'web' AS channel,
           (SELECT AVG(hpi.i_current_price)
            FROM high_price_items hpi
            WHERE hpi.i_category = i.i_category) AS avg_price
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
      ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category IN (SELECT DISTINCT i_category FROM high_price_items)
    GROUP BY d.d_year, i.i_category
) AS combined
ORDER BY year,
         total_sales DESC
