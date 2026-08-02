WITH sales_keys AS (
    SELECT DISTINCT i.i_item_id, ca.ca_state
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_quantity >= 5
      AND t.t_hour BETWEEN 9 AND 17
),
sales_with_returns AS (
    SELECT DISTINCT i.i_item_id, ca.ca_state
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_return_quantity > 0
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT i_item_id, ca_state
FROM sales_keys
EXCEPT
SELECT i_item_id, ca_state
FROM sales_with_returns
LIMIT 100
