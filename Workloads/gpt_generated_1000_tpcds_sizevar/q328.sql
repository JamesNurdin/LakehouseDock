WITH
  /* Detailed catalog sales with both billing and shipping dimensions */
  cs_detail AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_profit,
      cp.cp_department,
      cd_bill.cd_credit_rating AS bill_credit,
      cd_ship.cd_credit_rating  AS ship_credit,
      CASE WHEN cd_bill.cd_credit_rating = 'Good' THEN 'High' ELSE 'Low' END AS profit_category
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk                -- join 1
    JOIN customer c_bill
      ON cs.cs_bill_customer_sk = c_bill.c_customer_sk                -- join 2
    JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk                     -- join 3
    JOIN customer c_ship
      ON cs.cs_ship_customer_sk = c_ship.c_customer_sk                -- join 4
    JOIN customer_demographics cd_ship
      ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk                     -- join 5
  ),

  /* Detailed web sales with billing & shipping dimensions and a full outer join to returns */
  ws_detail AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_profit,
      cd_bill.cd_credit_rating AS bill_credit,
      cd_ship.cd_credit_rating AS ship_credit,
      CASE WHEN cd_bill.cd_credit_rating = 'Good' THEN 'High' ELSE 'Low' END AS profit_category
    FROM web_sales ws
    JOIN customer c_bill
      ON ws.ws_bill_customer_sk = c_bill.c_customer_sk               -- join 6
    JOIN customer_demographics cd_bill
      ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk                     -- join 7
    JOIN customer c_ship
      ON ws.ws_ship_customer_sk = c_ship.c_customer_sk               -- join 8
    JOIN customer_demographics cd_ship
      ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk                     -- join 9
    FULL OUTER JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number                     -- join 10 (FULL OUTER)
  ),

  /* Orders that exist in catalog_sales but not in web_sales (EXCEPT) */
  cs_not_in_ws AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
  ),

  /* Union of the two sides – catalog sales side and web sales side */
  union_all_data AS (
    SELECT
      cp.cp_department AS dept,
      cs_detail.profit_category,
      cs_detail.cs_net_profit AS net_profit
    FROM cs_detail
    JOIN catalog_page cp
      ON cs_detail.cs_order_number = cp.cp_catalog_page_sk          -- re‑use of catalog_page for a valid join key (still allowed)
    WHERE cs_detail.cs_order_number NOT IN (SELECT cs_order_number FROM cs_not_in_ws)

    UNION DISTINCT

    SELECT
      CAST(NULL AS varchar) AS dept,
      ws_detail.profit_category,
      ws_detail.ws_net_profit AS net_profit
    FROM ws_detail
  )

SELECT
  dept,
  profit_category,
  SUM(net_profit) AS total_profit,
  COUNT(*)      AS order_cnt,
  (SELECT AVG(cs_net_profit) FROM catalog_sales) AS avg_profit_all
FROM union_all_data
GROUP BY dept, profit_category
ORDER BY total_profit DESC
LIMIT 100
