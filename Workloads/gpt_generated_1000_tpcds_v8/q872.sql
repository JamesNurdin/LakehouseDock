WITH
  sales_agg AS (
    SELECT
      cs.cs_order_number,
      cs.cs_ship_date_sk,
      cs.cs_net_paid_inc_ship,
      cc1.cc_state            AS cc_state,
      w1.w_state               AS w_state,
      ca_bill.ca_state         AS bill_state,
      ca_ship.ca_state         AS ship_state,
      CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
      LAG(cs.cs_net_paid_inc_ship) OVER (PARTITION BY cc1.cc_state ORDER BY cs.cs_ship_date_sk) AS prev_net_paid,
      (SELECT SUM(wr2.wr_return_amt)
         FROM web_returns wr2
        WHERE wr2.wr_order_number = cs.cs_order_number)                                 AS total_return_amt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc1 ON cs.cs_call_center_sk = cc1.cc_call_center_sk
    JOIN tpcds.call_center cc2 ON cs.cs_call_center_sk = cc2.cc_call_center_sk
    JOIN tpcds.warehouse w1   ON cs.cs_warehouse_sk = w1.w_warehouse_sk
    JOIN tpcds.warehouse w2   ON cs.cs_warehouse_sk = w2.w_warehouse_sk
    JOIN tpcds.customer_address ca_bill  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_address ca_ship  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN tpcds.customer_address ca_ship2 ON cs.cs_ship_addr_sk = ca_ship2.ca_address_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450825 AND 2450894
  ),
  returns_agg AS (
    SELECT
      wr.wr_order_number,
      wr.wr_returned_date_sk,
      wr.wr_return_amt,
      ca_ref.ca_state          AS refunded_state,
      ca_ret.ca_state          AS returning_state,
      CASE WHEN wr.wr_net_loss > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag
    FROM tpcds.web_returns wr
    JOIN tpcds.customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN tpcds.customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450825 AND 2450894
  ),
  intersect_orders AS (
    SELECT cs.cs_order_number AS order_number FROM tpcds.catalog_sales cs
    INTERSECT
    SELECT wr.wr_order_number      FROM tpcds.web_returns wr
  )
SELECT
  cc_state,
  w_state,
  COUNT(DISTINCT order_number)                     AS order_cnt,
  SUM(COALESCE(net_paid_inc_ship, 0))              AS total_net_paid,
  SUM(COALESCE(total_return_amt, 0))               AS total_returns,
  MIN(ship_date_sk)                                AS min_ship_date,
  MAX(ship_date_sk)                                AS max_ship_date
FROM (
  SELECT
    cs_order_number      AS order_number,
    cs_ship_date_sk      AS ship_date_sk,
    cs_net_paid_inc_ship AS net_paid_inc_ship,
    cc_state,
    w_state,
    profit_flag,
    total_return_amt,
    prev_net_paid
  FROM sales_agg

  UNION

  SELECT
    wr_order_number      AS order_number,
    wr_returned_date_sk  AS ship_date_sk,
    NULL                 AS net_paid_inc_ship,
    refunded_state       AS cc_state,
    NULL                 AS w_state,
    loss_flag            AS profit_flag,
    wr_return_amt        AS total_return_amt,
    NULL                 AS prev_net_paid
  FROM returns_agg
) u
WHERE order_number IN (SELECT order_number FROM intersect_orders)
GROUP BY ROLLUP (cc_state, w_state)
ORDER BY cc_state, w_state
LIMIT 100
