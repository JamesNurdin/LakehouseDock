WITH
  catalog_sales_agg AS (
    SELECT
      cs.cs_bill_customer_sk      AS cust_sk,
      d.d_year,
      SUM(cs.cs_net_paid)         AS catalog_net_paid,
      SUM(cs.cs_quantity)         AS catalog_qty,
      p.p_promo_id,
      cp.cp_department,
      t.t_hour
    FROM catalog_sales cs
    JOIN date_dim d      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p     ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND cp.cp_department = 'DEPARTMENT'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cs.cs_bill_customer_sk, d.d_year, p.p_promo_id, cp.cp_department, t.t_hour
  ),
  store_sales_agg AS (
    SELECT
      ss.ss_customer_sk AS cust_sk,
      d.d_year,
      SUM(ss.ss_net_paid) AS store_net_paid,
      SUM(ss.ss_quantity) AS store_qty,
      p.p_promo_id,
      t.t_hour
    FROM store_sales ss
    JOIN date_dim d      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p     ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_customer_sk, d.d_year, p.p_promo_id, t.t_hour
  ),
  web_sales_agg AS (
    SELECT
      ws.ws_bill_customer_sk AS cust_sk,
      d.d_year,
      SUM(ws.ws_net_paid)    AS web_net_paid,
      SUM(ws.ws_quantity)    AS web_qty,
      p.p_promo_id,
      wp.wp_type,
      t.t_hour
    FROM web_sales ws
    JOIN date_dim d      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t      ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p     ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp     ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY ws.ws_bill_customer_sk, d.d_year, p.p_promo_id, wp.wp_type, t.t_hour
  ),
  catalog_returns_agg AS (
    SELECT
      cr.cr_refunded_customer_sk AS cust_sk,
      d.d_year,
      SUM(cr.cr_return_amount)   AS catalog_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cr.cr_refunded_customer_sk, d.d_year
  ),
  store_returns_agg AS (
    SELECT
      sr.sr_customer_sk AS cust_sk,
      d.d_year,
      SUM(sr.sr_return_amt) AS store_return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_customer_sk, d.d_year
  ),
  web_returns_agg AS (
    SELECT
      wr.wr_refunded_customer_sk AS cust_sk,
      d.d_year,
      SUM(wr.wr_return_amt) AS web_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY wr.wr_refunded_customer_sk, d.d_year
  ),
  inventory_agg AS (
    SELECT
      d.d_year,
      SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year
  )
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  ca.ca_city,
  ca.ca_state,
  d.d_year,
  (
    COALESCE(cs.catalog_net_paid, 0) - COALESCE(cr.catalog_return_amount, 0) +
    COALESCE(ss.store_net_paid, 0) - COALESCE(sr.store_return_amount, 0) +
    COALESCE(ws.web_net_paid, 0)   - COALESCE(wr.web_return_amount, 0)
  ) AS net_sales,
  COALESCE(cs.catalog_qty, 0) + COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0) AS total_quantity,
  ia.total_inventory_qty,
  RANK() OVER (PARTITION BY d.d_year ORDER BY (
    COALESCE(cs.catalog_net_paid, 0) + COALESCE(ss.store_net_paid, 0) + COALESCE(ws.web_net_paid, 0)
  ) DESC) AS yearly_sales_rank
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d          ON c.c_first_sales_date_sk = d.d_date_sk
LEFT JOIN catalog_sales_agg cs ON cs.cust_sk = c.c_customer_sk AND cs.d_year = d.d_year
LEFT JOIN catalog_returns_agg cr ON cr.cust_sk = c.c_customer_sk AND cr.d_year = d.d_year
LEFT JOIN store_sales_agg ss   ON ss.cust_sk = c.c_customer_sk AND ss.d_year = d.d_year
LEFT JOIN store_returns_agg sr ON sr.cust_sk = c.c_customer_sk AND sr.d_year = d.d_year
LEFT JOIN web_sales_agg ws     ON ws.cust_sk = c.c_customer_sk AND ws.d_year = d.d_year
LEFT JOIN web_returns_agg wr   ON wr.cust_sk = c.c_customer_sk AND wr.d_year = d.d_year
LEFT JOIN inventory_agg ia     ON ia.d_year = d.d_year
WHERE ca.ca_state = 'CA'
ORDER BY net_sales DESC
LIMIT 100
