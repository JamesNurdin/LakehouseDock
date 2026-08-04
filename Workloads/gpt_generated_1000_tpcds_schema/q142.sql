/*
  Goal: Compare high‑value sales (ext_sales_price > 1000) from store_sales and web_sales for the year 2001, including customers that may have no matching sales (using FULL OUTER JOIN). The two result sets are combined with UNION ALL, ordered by year and sales amount, and limited to the top 100 rows.
*/
SELECT
  sold_date_sk,
  d_year,
  item_sk,
  ext_sales_price,
  customer_id,
  first_name,
  last_name
FROM (
  SELECT
    ss.ss_sold_date_sk        AS sold_date_sk,
    d.d_year                  AS d_year,
    ss.ss_item_sk             AS item_sk,
    ss.ss_ext_sales_price     AS ext_sales_price,
    c.c_customer_id           AS customer_id,
    c.c_first_name            AS first_name,
    c.c_last_name             AS last_name
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  FULL OUTER JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND ss.ss_ext_sales_price > 1000

  UNION ALL

  SELECT
    ws.ws_sold_date_sk        AS sold_date_sk,
    d.d_year                  AS d_year,
    ws.ws_item_sk              AS item_sk,
    ws.ws_ext_sales_price      AS ext_sales_price,
    c.c_customer_id           AS customer_id,
    c.c_first_name            AS first_name,
    c.c_last_name             AS last_name
  FROM web_sales ws
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  FULL OUTER JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND ws.ws_ext_sales_price > 1000
) AS combined
ORDER BY d_year DESC, ext_sales_price DESC
LIMIT 100
