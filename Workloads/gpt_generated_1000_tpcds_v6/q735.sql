WITH top_customers AS (
    SELECT
        c.c_customer_sk,
        concat(c.c_first_name, ' ', c.c_last_name) AS cust_name,
        SUM(ws.ws_net_profit) AS total_profit,
        (
            SELECT COUNT(DISTINCT ws2.ws_bill_customer_sk)
            FROM web_sales ws2
            JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
            WHERE i2.i_manufact_id = 260
        ) AS total_customers_for_manufact
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_manufact_id = 260
      AND ws.ws_net_profit > 0
    GROUP BY c.c_customer_sk, concat(c.c_first_name, ' ', c.c_last_name)
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT DISTINCT entity_type, entity_id, description, metric
FROM (
    SELECT
        'customer' AS entity_type,
        tc.c_customer_sk AS entity_id,
        tc.cust_name AS description,
        tc.total_profit AS metric
    FROM top_customers tc

    UNION ALL

    SELECT
        'item' AS entity_type,
        i.i_item_sk AS entity_id,
        i.i_product_name AS description,
        CAST(inv.inv_quantity_on_hand AS double) AS metric
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand < 50
      AND i.i_class = 'infants'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_item_sk = i.i_item_sk
            AND ws.ws_net_profit > 0
      )
) AS combined
LIMIT 100
