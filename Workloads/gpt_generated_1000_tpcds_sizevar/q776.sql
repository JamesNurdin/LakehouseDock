WITH
  agg_sales AS (
    SELECT
      cs_order_number,
      cs_bill_customer_sk,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_catalog_page_sk,
      cs_promo_sk,
      SUM(cs_net_paid) AS total_paid,
      SUM(cs_quantity) AS total_qty
    FROM catalog_sales
    GROUP BY
      cs_order_number,
      cs_bill_customer_sk,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_catalog_page_sk,
      cs_promo_sk
  ),
  agg_web AS (
    SELECT
      ws_order_number AS order_number,
      ws_bill_customer_sk AS bill_customer_sk,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_promo_sk,
      SUM(ws_net_paid) AS total_paid,
      SUM(ws_quantity) AS total_qty
    FROM web_sales
    GROUP BY
      ws_order_number,
      ws_bill_customer_sk,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_promo_sk
  ),
  agg_returns AS (
    SELECT
      cr_order_number,
      SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_order_number
  )
SELECT *
FROM (
  SELECT
    s.cs_order_number        AS order_number,
    c.c_customer_id,
    d_sold.d_date            AS sold_date,
    t_sold.t_hour,
    cp.cp_department,
    p.p_promo_name,
    s.total_paid,
    s.total_qty,
    CASE
      WHEN r.total_return_amount > 0 THEN 'Returned'
      ELSE 'No Return'
    END                     AS return_flag
  FROM agg_sales s
  JOIN customer c ON s.cs_bill_customer_sk = c.c_customer_sk
  JOIN date_dim d_sold ON s.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold ON s.cs_sold_time_sk = t_sold.t_time_sk
  JOIN catalog_page cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
  RIGHT OUTER JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
  LEFT JOIN agg_returns r ON s.cs_order_number = r.cr_order_number
  JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
  JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
  WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_order_number = s.cs_order_number
  )

  UNION

  SELECT
    w.order_number,
    c.c_customer_id,
    d_sold.d_date,
    t_sold.t_hour,
    NULL                     AS cp_department,
    p.p_promo_name,
    w.total_paid,
    w.total_qty,
    CASE
      WHEN r.total_return_amount > 0 THEN 'Returned'
      ELSE 'No Return'
    END                     AS return_flag
  FROM agg_web w
  JOIN customer c ON w.bill_customer_sk = c.c_customer_sk
  JOIN date_dim d_sold ON w.ws_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold ON w.ws_sold_time_sk = t_sold.t_time_sk
  RIGHT OUTER JOIN promotion p ON w.ws_promo_sk = p.p_promo_sk
  LEFT JOIN agg_returns r ON w.order_number = r.cr_order_number
  WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_order_number = w.order_number
  )
) AS combined
WHERE combined.order_number IN (
  SELECT order_number FROM (
    SELECT cs_order_number AS order_number FROM agg_sales
    UNION ALL
    SELECT order_number FROM agg_web
  ) AS all_orders
  EXCEPT
  SELECT cr_order_number FROM catalog_returns WHERE cr_return_amount = 0
)
LIMIT 100
