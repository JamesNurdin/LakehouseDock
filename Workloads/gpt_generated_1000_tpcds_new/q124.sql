(
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE i.i_category = 'Sports'
      AND ss.ss_quantity > 2
) INTERSECT (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE i.i_category = 'Sports'
      AND ws.ws_quantity > 1
)
UNION (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_ship_mode_sk = 5
      AND cs.cs_net_paid_inc_ship > 2000
)
ORDER BY c_customer_id
LIMIT 100
