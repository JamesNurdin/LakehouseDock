/*
Goal: Identify the top‑earning customers for the year 1998 who bought from United States web sites, belong to a CA store, and whose last name is 'Morris'. The query joins all nine selected TPC‑DS tables, applies multiple filters, uses EXISTS/NOT EXISTS subqueries, aggregates sales, ranks customers by profit, filters groups with HAVING, and returns the top 100 rows.
*/
WITH sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        d_sold.d_year,
        SUM(ws.ws_net_profit)      AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*)                   AS order_cnt
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    GROUP BY
        ws.ws_bill_customer_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        d_sold.d_year
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_sold.d_year,
    s.s_store_name,
    cp.cp_department,
    we.web_name,
    wa.w_warehouse_name,
    sa.total_profit,
    sa.total_sales,
    sa.order_cnt,
    RANK() OVER (PARTITION BY d_sold.d_year ORDER BY sa.total_profit DESC) AS profit_rank
FROM sales_agg sa
JOIN customer c
  ON sa.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_sold
  ON sa.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
  ON sa.ws_sold_time_sk = t.t_time_sk
JOIN web_page wp
  ON sa.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
  ON sa.ws_web_site_sk = we.web_site_sk
JOIN warehouse wa
  ON sa.ws_warehouse_sk = wa.w_warehouse_sk
JOIN store s
  ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN catalog_page cp
  ON cp.cp_start_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 1998
  AND we.web_country = 'United States'
  AND s.s_state = 'CA'
  AND c.c_last_name = 'Morris'
  AND cp.cp_department = 'Sports'
  AND t.t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_sk = cp.cp_catalog_page_sk
          AND cp2.cp_type = 'PROMO'
    )
  AND NOT EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
          AND wp2.wp_type = 'error'
    )
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_sold.d_year,
    s.s_store_name,
    cp.cp_department,
    we.web_name,
    wa.w_warehouse_name,
    sa.total_profit,
    sa.total_sales,
    sa.order_cnt
HAVING SUM(sa.total_profit) > 10000
ORDER BY profit_rank, sa.total_profit DESC
LIMIT 100
