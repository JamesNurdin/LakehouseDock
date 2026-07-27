WITH sales_2000 AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    d.d_year,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2000
    AND i.i_category = 'Sports'
    AND EXISTS (
        SELECT 1 FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_max_ad_count > 0
    )
  GROUP BY c.c_customer_sk, c.c_customer_id, d.d_year
  HAVING SUM(ws.ws_ext_sales_price) > 1000
),
sales_2001 AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    d.d_year,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Books'
    AND EXISTS (
        SELECT 1 FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_max_ad_count > 0
    )
  GROUP BY c.c_customer_sk, c.c_customer_id, d.d_year
  HAVING SUM(ws.ws_ext_sales_price) > 1000
)
SELECT DISTINCT
  s.c_customer_id,
  s.d_year,
  s.total_sales,
  s.total_profit,
  s.profit_status,
  CASE
    WHEN s.avg_discount > (SELECT AVG(ws2.ws_ext_discount_amt) FROM web_sales ws2) THEN 'Above Avg Discount'
    ELSE 'Below Avg Discount'
  END AS discount_comparison,
  s.sales_rank
FROM (
  SELECT * FROM sales_2000
  UNION ALL
  SELECT * FROM sales_2001
) s
WHERE s.sales_rank <= 10
ORDER BY s.d_year, s.total_sales DESC
