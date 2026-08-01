WITH combined AS (
    SELECT
        'web_sales' AS event_type,
        ws.ws_sold_date_sk AS date_key,
        c.c_customer_id AS entity_id,
        ws.ws_ext_sales_price AS amount,
        CASE WHEN ws.ws_ext_sales_price > 1000 THEN 'high' ELSE 'low' END AS amount_category,
        t.t_hour AS hour_of_day,
        CASE WHEN EXISTS (
            SELECT 1 FROM web_sales ws2
            WHERE ws2.ws_item_sk = i.i_item_sk AND ws2.ws_quantity > 5
        ) THEN 1 ELSE 0 END AS high_qty_flag
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE i.i_category = 'Electronics'
      AND t.t_hour BETWEEN 9 AND 17

    UNION ALL

    SELECT
        'store_return' AS event_type,
        sr.sr_returned_date_sk AS date_key,
        s.s_store_id AS entity_id,
        sr.sr_return_amt AS amount,
        CASE WHEN sr.sr_return_amt > 500 THEN 'high' ELSE 'low' END AS amount_category,
        t.t_hour AS hour_of_day,
        CASE WHEN r.r_reason_id IN (
            SELECT r2.r_reason_id FROM reason r2 WHERE r2.r_reason_sk = r.r_reason_sk AND r2.r_reason_id LIKE 'A%'
        ) THEN 1 ELSE 0 END AS high_qty_flag
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_state = 'CA'
      AND sr.sr_return_amt > 0
)
SELECT
    event_type,
    date_key,
    entity_id,
    amount,
    amount_category,
    hour_of_day,
    high_qty_flag,
    ROW_NUMBER() OVER (PARTITION BY event_type ORDER BY amount DESC) AS rn
FROM combined
ORDER BY event_type, amount DESC
LIMIT 100
