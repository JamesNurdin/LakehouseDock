WITH ss_data AS (
    SELECT
        s.s_store_name,
        p_ss.p_promo_name AS p_promo_name,
        ca_ss.ca_state,
        t_ss.t_hour,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
),
ws_data AS (
    SELECT
        ws_site.web_name,
        p_ws.p_promo_name AS ws_promo_name,
        ca_ws_bill.ca_state AS bill_state,
        ca_ws_ship.ca_state AS ship_state,
        t_ws.t_hour AS ws_hour,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        w_ws.w_warehouse_name,
        inv.inv_quantity_on_hand
    FROM web_sales ws
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN customer_address ca_ws_bill
        ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_address ca_ws_ship
        ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w_ws.w_warehouse_sk
)
SELECT
    ss_data.s_store_name,
    ss_data.p_promo_name,
    ws_data.web_name,
    ws_data.ws_promo_name,
    SUM(ss_data.ss_quantity) AS total_store_quantity,
    SUM(ws_data.ws_quantity) AS total_web_quantity,
    SUM(ss_data.ss_net_paid) AS total_store_net_paid,
    SUM(ws_data.ws_net_paid) AS total_web_net_paid,
    AVG(ss_data.ss_ext_discount_amt) AS avg_store_discount,
    AVG(ws_data.ws_ext_discount_amt) AS avg_web_discount
FROM ss_data
JOIN ws_data
    ON ss_data.ca_state = ws_data.bill_state
WHERE ss_data.t_hour BETWEEN 9 AND 17
  AND ws_data.ws_hour BETWEEN 9 AND 17
GROUP BY
    ss_data.s_store_name,
    ss_data.p_promo_name,
    ws_data.web_name,
    ws_data.ws_promo_name
HAVING SUM(ss_data.ss_net_paid) > 10000
ORDER BY total_store_net_paid DESC
LIMIT 100
