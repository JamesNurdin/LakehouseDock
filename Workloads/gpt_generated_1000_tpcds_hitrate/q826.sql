WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_web_site_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
      AND ws.ws_sales_price > 10
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451074
)
SELECT
    c.c_customer_id,
    d_sold.d_year,
    p.p_promo_name,
    w.w_warehouse_name,
    sm.sm_type,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_net_profit,
    inv.inv_quantity_on_hand,
    cr.cr_return_amount,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d_sold.d_date) AS rn_customer,
    SUM(ws.ws_net_profit) OVER (
        PARTITION BY c.c_customer_id
        ORDER BY d_sold.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_profit,
    LAG(ws.ws_sales_price) OVER (PARTITION BY c.c_customer_id ORDER BY d_sold.d_date) AS prev_sales_price
FROM sales_data ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
                     AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sold.d_date_sk
                         AND cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE p.p_purpose = 'Unknown'
  AND w.w_state = 'CA'
  AND d_sold.d_year = 2000
  AND c.c_customer_id NOT IN (
        SELECT c2.c_customer_id
        FROM customer c2
        WHERE c2.c_preferred_cust_flag = 'N'
    )
ORDER BY c.c_customer_id, d_sold.d_date
LIMIT 100
