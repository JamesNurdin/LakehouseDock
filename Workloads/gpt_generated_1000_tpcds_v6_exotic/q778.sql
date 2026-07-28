WITH ws_part AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_sold_time_sk AS time_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ca.ca_state AS cust_state,
        cd.cd_gender AS gender,
        p.p_promo_name AS promo_name,
        w.w_warehouse_name AS warehouse_name,
        we.web_site_id AS web_site_id,
        w.w_warehouse_id AS warehouse_id,
        ws.ws_item_sk AS item_sk,
        (ws.ws_quantity * ws.ws_list_price) AS total_amount
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
      AND we.web_state = 'CA'
      AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
      AND i.inv_quantity_on_hand > 0
      AND EXISTS (
          SELECT 1
          FROM store s
          WHERE s.s_state = 'CA'
            AND s.s_store_sk = ws.ws_warehouse_sk
      )
),
sr_part AS (
    SELECT
        sr.sr_ticket_number AS order_number,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_return_time_sk AS time_sk,
        sr.sr_return_quantity AS quantity,
        sr.sr_return_amt AS net_paid,
        sr.sr_net_loss AS net_profit,
        ca.ca_state AS cust_state,
        cd.cd_gender AS gender,
        NULL AS promo_name,
        NULL AS warehouse_name,
        NULL AS web_site_id,
        NULL AS warehouse_id,
        sr.sr_item_sk AS item_sk,
        (sr.sr_return_quantity * sr.sr_return_amt) AS total_amount
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
      AND sr.sr_return_quantity > 0
)
SELECT
    order_number,
    date_sk,
    time_sk,
    quantity,
    net_paid,
    net_profit,
    cust_state,
    gender,
    promo_name,
    warehouse_name,
    web_site_id,
    warehouse_id,
    item_sk,
    total_amount,
    RANK() OVER (PARTITION BY cust_state ORDER BY total_amount DESC) AS state_rank,
    ROW_NUMBER() OVER (ORDER BY total_amount DESC) AS global_rank
FROM (
    SELECT * FROM ws_part
    UNION ALL
    SELECT * FROM sr_part
) combined
ORDER BY total_amount DESC
LIMIT 100
