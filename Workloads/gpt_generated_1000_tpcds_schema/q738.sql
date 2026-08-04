WITH
  orders_a AS (
    SELECT DISTINCT cs_order_number AS order_num
    FROM catalog_sales
    WHERE cs_net_profit > 1000
      AND cs_ship_date_sk BETWEEN 2450800 AND 2450900
      AND cs_quantity >= 2
  ),
  orders_b AS (
    SELECT DISTINCT wr_order_number AS order_num
    FROM web_returns
    WHERE wr_net_loss < -100
      AND wr_fee > 30
      AND wr_return_quantity >= 1
  ),
  common_orders AS (
    SELECT order_num FROM orders_a
    INTERSECT
    SELECT order_num FROM orders_b
  ),
  base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_profit,
      cs.cs_quantity,
      cs.cs_ext_ship_cost,
      wr.wr_return_amt,
      wr.wr_fee,
      cd_bill.cd_gender AS bill_gender,
      cd_ship.cd_gender AS ship_gender,
      wr.wr_return_quantity
    FROM catalog_sales cs
    FULL OUTER JOIN web_returns wr
      ON cs.cs_order_number = wr.wr_order_number
    LEFT JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN customer_demographics cd_ship
      ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE cs.cs_order_number IN (SELECT order_num FROM common_orders)
      AND (cs.cs_ext_ship_cost > 500 OR wr.wr_fee > 30)
      AND (cs.cs_quantity >= 2 OR wr.wr_return_quantity >= 1)
  )
SELECT DISTINCT
  b.cs_order_number,
  b.bill_gender,
  b.ship_gender,
  b.cs_net_profit,
  b.cs_ext_ship_cost,
  b.wr_return_amt,
  RANK() OVER (PARTITION BY b.bill_gender ORDER BY b.cs_net_profit DESC) AS profit_rank,
  (
    SELECT SUM(cs2.cs_net_profit)
    FROM catalog_sales cs2
    WHERE cs2.cs_order_number = b.cs_order_number
  ) AS total_profit_for_order,
  (
    SELECT COUNT(*)
    FROM web_returns wr2
    WHERE wr2.wr_order_number = b.cs_order_number
  ) AS return_count
FROM base b
WHERE b.cs_net_profit IS NOT NULL
UNION
SELECT DISTINCT
  b.cs_order_number,
  b.ship_gender AS bill_gender,
  b.bill_gender AS ship_gender,
  b.cs_net_profit,
  b.cs_ext_ship_cost,
  b.wr_return_amt,
  RANK() OVER (PARTITION BY b.ship_gender ORDER BY b.cs_net_profit DESC) AS profit_rank,
  (
    SELECT SUM(cs2.cs_net_profit)
    FROM catalog_sales cs2
    WHERE cs2.cs_order_number = b.cs_order_number
  ) AS total_profit_for_order,
  (
    SELECT COUNT(*)
    FROM web_returns wr2
    WHERE wr2.wr_order_number = b.cs_order_number
  ) AS return_count
FROM base b
WHERE b.cs_net_profit IS NOT NULL
ORDER BY profit_rank, cs_order_number
