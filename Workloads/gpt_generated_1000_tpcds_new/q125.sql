WITH inventory_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_date_sk
),
sr_cust AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country
    FROM store_returns sr
    FULL OUTER JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
)
SELECT
    d.d_year,
    sm.sm_carrier,
    wp.wp_type,
    sc.c_birth_country,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(sc.sr_return_amt) AS total_store_return_amt,
    SUM(i.total_qty) AS total_inventory_qty,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(ws.ws_net_profit) AS avg_net_profit
FROM sr_cust sc
JOIN date_dim d
    ON sc.sr_returned_date_sk = d.d_date_sk
JOIN inventory_agg i
    ON i.inv_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_refunded_customer_sk = sc.c_customer_sk
WHERE d.d_year = 2001
  AND sm.sm_code = 'AIR'
  AND i.total_qty > 300
  AND ws.ws_net_profit > 100
  AND wp.wp_type = 'article'
GROUP BY d.d_year, sm.sm_carrier, wp.wp_type, sc.c_birth_country
ORDER BY total_net_paid DESC
LIMIT 100
