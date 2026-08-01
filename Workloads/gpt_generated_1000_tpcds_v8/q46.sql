WITH ws_base AS (
   SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_bill_customer_sk,
      ws.ws_bill_cdemo_sk,
      ws.ws_bill_hdemo_sk,
      ws.ws_ship_cdemo_sk,
      ws.ws_ship_hdemo_sk,
      ws.ws_web_page_sk,
      ws.ws_warehouse_sk,
      ws.ws_promo_sk,
      ws.ws_net_paid,
      ws.ws_ext_discount_amt,
      ws.ws_quantity,
      ws.ws_net_profit,
      row_number() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn_ws
   FROM web_sales ws
   WHERE ws.ws_net_paid > 0
),

joined AS (
   SELECT
      ws_base.*,
      cd_bill.cd_gender AS bill_gender,
      cd_bill.cd_demo_sk AS bill_cdemo_sk,
      cd_ship.cd_marital_status AS ship_marital_status,
      cd_ship.cd_demo_sk AS ship_cdemo_sk,
      hd_bill.hd_income_band_sk AS bill_income_band,
      hd_ship.hd_vehicle_count AS ship_vehicle_count,
      p_wr.p_promo_name,
      wp.wp_type,
      w.w_warehouse_name,
      ss.ss_ticket_number,
      wr.wr_order_number AS return_order_number,
      (SELECT sum(ws2.ws_net_paid)
       FROM web_sales ws2
       WHERE ws2.ws_bill_customer_sk = ws_base.ws_bill_customer_sk) AS total_customer_sales
   FROM ws_base
   JOIN customer_demographics cd_bill
     ON ws_base.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN customer_demographics cd_ship
     ON ws_base.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
   JOIN household_demographics hd_bill
     ON ws_base.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN household_demographics hd_ship
     ON ws_base.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN promotion p_wr
     ON ws_base.ws_promo_sk = p_wr.p_promo_sk
   RIGHT JOIN web_page wp
     ON ws_base.ws_web_page_sk = wp.wp_web_page_sk
   JOIN warehouse w
     ON ws_base.ws_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN store_sales ss
     ON ss.ss_promo_sk = p_wr.p_promo_sk
   LEFT JOIN web_returns wr
     ON wr.wr_order_number = ws_base.ws_order_number
),

filtered AS (
   SELECT *
   FROM joined
   WHERE return_order_number IS NULL
     AND NOT EXISTS (
         SELECT 1
         FROM web_returns wr2
         WHERE wr2.wr_returning_cdemo_sk = bill_cdemo_sk
           AND wr2.wr_returned_date_sk = ws_sold_date_sk
     )
)

SELECT
   ws_order_number,
   ws_sold_date_sk,
   bill_gender,
   ship_marital_status,
   bill_income_band,
   ship_vehicle_count,
   p_promo_name,
   wp_type,
   w_warehouse_name,
   SUM(ws_net_paid) AS total_net_paid,
   AVG(ws_ext_discount_amt) AS avg_discount,
   COUNT(DISTINCT rn_ws) AS distinct_bill_rows,
   MAX(total_customer_sales) AS max_customer_total_sales
FROM filtered
GROUP BY
   ws_order_number,
   ws_sold_date_sk,
   bill_gender,
   ship_marital_status,
   bill_income_band,
   ship_vehicle_count,
   p_promo_name,
   wp_type,
   w_warehouse_name
ORDER BY total_net_paid DESC
LIMIT 100
