WITH sales_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_web_site_sk,
        ws_ship_mode_sk,
        ws_bill_hdemo_sk,
        ws_bill_addr_sk,
        ws_ship_hdemo_sk,
        ws_ship_addr_sk,
        ws_web_page_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt,
        AVG(ws_ext_tax) AS avg_ext_tax
    FROM tpcds.web_sales
    WHERE ws_ext_tax > 0
      AND ws_ext_list_price BETWEEN 500 AND 20000
      AND ws_quantity >= 1
      AND ws_net_paid_inc_ship_tax >= 100
      AND ws_ship_date_sk IS NOT NULL
      AND ws_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY
        ws_warehouse_sk,
        ws_web_site_sk,
        ws_ship_mode_sk,
        ws_bill_hdemo_sk,
        ws_bill_addr_sk,
        ws_ship_hdemo_sk,
        ws_ship_addr_sk,
        ws_web_page_sk
)
SELECT DISTINCT
    ws.web_name AS web_site_name,
    w.w_warehouse_name AS warehouse_name,
    sm.sm_carrier AS carrier,
    ca_bill.ca_gmt_offset AS bill_gmt_offset,
    hd_bill.hd_vehicle_count AS bill_vehicle_cnt,
    total_net_paid,
    order_cnt,
    avg_ext_tax,
    RANK() OVER (PARTITION BY ws.web_name ORDER BY total_net_paid DESC) AS warehouse_rank
FROM sales_agg sa
JOIN tpcds.warehouse w
  ON sa.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.ship_mode sm
  ON sa.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_site ws
  ON sa.ws_web_site_sk = ws.web_site_sk
JOIN tpcds.household_demographics hd_bill
  ON sa.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship
  ON sa.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.customer_address ca_bill
  ON sa.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
  ON sa.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.web_page wp
  ON sa.ws_web_page_sk = wp.wp_web_page_sk
WHERE ca_bill.ca_gmt_offset = -5.00
  AND ca_ship.ca_state = 'CA'
  AND hd_bill.hd_vehicle_count >= 0
  AND hd_ship.hd_buy_potential = '>10000'
  AND sm.sm_carrier = 'UPS'
  AND w.w_warehouse_sq_ft > 50000
  AND EXISTS (
        SELECT 1 FROM tpcds.web_page wp2
        WHERE wp2.wp_web_page_sk = sa.ws_web_page_sk
          AND wp2.wp_url LIKE '%example%'
    )
ORDER BY total_net_paid DESC
LIMIT 100
