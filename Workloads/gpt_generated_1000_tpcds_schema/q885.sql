WITH
  cr_sample AS (
    SELECT cr_order_number, cr_return_amount
    FROM catalog_returns TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_amount > 0
  ),
  cs AS (
    SELECT cs_order_number, cs_net_paid, cs_item_sk, cs_warehouse_sk,
           cs_bill_customer_sk, cs_ship_customer_sk
    FROM catalog_sales
    WHERE cs_net_paid > 0
  ),
  wr AS (
    SELECT wr_order_number, wr_return_amt, wr_web_page_sk, wr_reason_sk,
           wr_refunded_customer_sk
    FROM web_returns
    WHERE wr_return_amt > 0
  ),
  intersect_orders AS (
    SELECT cr_order_number AS order_number FROM cr_sample
    INTERSECT
    SELECT wr_order_number FROM wr
  ),
  union_orders AS (
    SELECT DISTINCT cs_order_number AS order_number, cs_net_paid AS amount
    FROM cs
    UNION
    SELECT DISTINCT sr_ticket_number AS order_number, sr_return_amt AS amount
    FROM store_returns
  ),
  base AS (
    SELECT
      u.order_number,
      u.amount,
      c.c_customer_id,
      ca.ca_state,
      hd.hd_income_band_sk,
      r.r_reason_desc,
      w.w_warehouse_name,
      wp.wp_url,
      cr.cr_return_amount,
      sr.sr_return_amt,
      wr.wr_return_amt
    FROM union_orders u
    JOIN catalog_sales cs ON u.order_number = cs.cs_order_number
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE u.order_number IN (SELECT order_number FROM intersect_orders)
  ),
  final_set AS (
    SELECT
      ROW_NUMBER() OVER (ORDER BY (amount + COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) DESC) AS rn,
      order_number,
      amount,
      c_customer_id,
      ca_state,
      hd_income_band_sk,
      r_reason_desc,
      w_warehouse_name,
      wp_url,
      (amount + COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) AS total_amount
    FROM base
  ),
  excluded AS (
    SELECT
      ROW_NUMBER() OVER (ORDER BY (amount + COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) DESC) AS rn,
      order_number,
      amount,
      c_customer_id,
      ca_state,
      hd_income_band_sk,
      r_reason_desc,
      w_warehouse_name,
      wp_url,
      (amount + COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) AS total_amount
    FROM base
    WHERE order_number NOT IN (SELECT order_number FROM intersect_orders)
  )
SELECT *
FROM final_set
EXCEPT
SELECT *
FROM excluded
ORDER BY total_amount DESC
LIMIT 100
