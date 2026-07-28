WITH qualified_items AS (
    SELECT i.i_item_sk,
           i.i_item_desc,
           i.i_category,
           regexp_extract(i.i_item_desc, '[A-Z]{2}[0-9]{3}') AS code
    FROM   item i
    WHERE  regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
       AND EXISTS (
           SELECT 1
           FROM   web_sales ws
           WHERE  ws.ws_item_sk = i.i_item_sk
             AND  ws.ws_quantity > 10
       )
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    sm.sm_ship_mode_id,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MAX(qualified_items.code) AS sample_code
FROM   catalog_sales cs
JOIN   qualified_items
       ON cs.cs_item_sk = qualified_items.i_item_sk
JOIN   customer c
       ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN   ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE  c.c_preferred_cust_flag = 'Y'
  AND  c.c_email_address LIKE '%@example.com'
  AND  sm.sm_type LIKE 'AIR%'
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    sm.sm_ship_mode_id
ORDER BY total_net_profit DESC
LIMIT 100
