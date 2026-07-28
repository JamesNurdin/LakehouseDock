WITH web AS (
    SELECT
        c.c_customer_id AS customer_id,
        'WEB_SALE' AS transaction_type,
        ws.ws_net_paid AS amount,
        ws.ws_sold_date_sk AS date_key,
        sm.sm_carrier AS carrier
    FROM web_sales ws
    INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451000 AND 2452000
      AND p.p_promo_name LIKE '%Discount%'
),
store AS (
    SELECT
        c.c_customer_id AS customer_id,
        'STORE_RETURN' AS transaction_type,
        sr.sr_return_amt_inc_tax AS amount,
        sr.sr_returned_date_sk AS date_key,
        CAST(NULL AS varchar) AS carrier
    FROM store_returns sr
    INNER JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_ship_cost > 100
      AND sr.sr_returned_date_sk BETWEEN 2451500 AND 2452500
)
SELECT
    t.customer_id,
    t.transaction_type,
    t.amount,
    t.date_key,
    t.carrier,
    ROW_NUMBER() OVER (PARTITION BY t.customer_id ORDER BY t.amount DESC) AS rn
FROM (
    SELECT customer_id, transaction_type, amount, date_key, carrier FROM web
    UNION ALL
    SELECT customer_id, transaction_type, amount, date_key, carrier FROM store
) t
ORDER BY t.amount DESC
LIMIT 100
