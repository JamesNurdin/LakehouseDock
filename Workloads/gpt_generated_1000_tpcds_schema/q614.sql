WITH
  sales_cte AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_item_sk,
      i.i_category,
      i.i_brand,
      cc.cc_name AS call_center_name,
      cp.cp_department,
      sm.sm_type AS ship_type,
      w.w_warehouse_name AS warehouse_name,
      cd_bill.cd_gender AS bill_gender,
      cd_ship.cd_gender AS ship_gender,
      cs.cs_net_paid,
      cs.cs_net_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  ),
  web_cte AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      i.i_category,
      i.i_brand,
      wp.wp_type AS page_type,
      sm.sm_type AS ship_type,
      w.w_warehouse_name AS warehouse_name,
      cd_bill.cd_gender AS bill_gender,
      cd_ship.cd_gender AS ship_gender,
      ws.ws_net_paid,
      ws.ws_net_profit,
      r.r_reason_desc,
      wr.wr_return_amt,
      wr.wr_net_loss
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  ),
  union_cte AS (
    SELECT
      cs_order_number AS order_number,
      cs_sold_date_sk AS sold_date_sk,
      cs_item_sk AS item_sk,
      i_category,
      i_brand,
      cs_net_paid AS net_paid,
      cs_net_profit AS net_profit,
      ship_type,
      warehouse_name,
      bill_gender,
      ship_gender
    FROM sales_cte
    UNION DISTINCT
    SELECT
      ws_order_number AS order_number,
      ws_sold_date_sk AS sold_date_sk,
      ws_item_sk AS item_sk,
      i_category,
      i_brand,
      ws_net_paid AS net_paid,
      ws_net_profit AS net_profit,
      ship_type,
      warehouse_name,
      bill_gender,
      ship_gender
    FROM web_cte
  ),
  catalog_orders AS (
    SELECT cs_order_number AS order_number FROM catalog_sales
  ),
  web_orders AS (
    SELECT ws_order_number AS order_number FROM web_sales
  ),
  diff_orders AS (
    SELECT order_number FROM catalog_orders
    EXCEPT
    SELECT order_number FROM web_orders
  )
SELECT
  u.order_number,
  u.sold_date_sk,
  u.item_sk,
  u.i_category AS category,
  u.i_brand AS brand,
  SUM(u.net_paid) AS total_net_paid,
  SUM(u.net_profit) AS total_net_profit,
  COUNT(*) AS rows_per_order
FROM union_cte u
FULL OUTER JOIN diff_orders d ON u.order_number = d.order_number
GROUP BY
  u.order_number,
  u.sold_date_sk,
  u.item_sk,
  u.i_category,
  u.i_brand
ORDER BY total_net_paid DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
