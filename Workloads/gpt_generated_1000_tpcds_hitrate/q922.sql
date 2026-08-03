WITH
    ss_keys AS (
        SELECT ss_ticket_number AS ticket,
               ss_store_sk,
               ss_quantity
        FROM store_sales
        WHERE ss_quantity > 5
          AND ss_store_sk IN (SELECT s_store_sk FROM store WHERE s_state = 'TX')
    ),
    sr_keys AS (
        SELECT sr_ticket_number AS ticket,
               sr_store_sk,
               sr_return_quantity
        FROM store_returns
        WHERE sr_return_quantity > 2
    ),
    ws_keys AS (
        SELECT ws_order_number AS ticket,
               ws_ship_mode_sk,
               ws_quantity
        FROM web_sales
        WHERE ws_quantity > 3
    ),
    ss_excluding_sr AS (
        SELECT ticket, ss_store_sk, ss_quantity
        FROM ss_keys
        EXCEPT
        SELECT ticket, sr_store_sk, sr_return_quantity
        FROM sr_keys
    ),
    intersect_set AS (
        SELECT ticket, ss_store_sk, ss_quantity
        FROM ss_excluding_sr
        INTERSECT
        SELECT ticket, ws_ship_mode_sk, ws_quantity
        FROM ws_keys
    ),
    final_set AS (
        SELECT
            ticket,
            ss_store_sk AS store_key,
            ss_quantity AS quantity,
            CASE WHEN ss_quantity > 10 THEN 'High' ELSE 'Medium' END AS quantity_category,
            ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY ss_quantity DESC) AS qty_rank,
            (SELECT SUM(sr_return_amt) FROM store_returns WHERE sr_return_quantity > 0) AS total_return_amount
        FROM intersect_set
    ),
    another_set AS (
        SELECT
            ws_order_number AS ticket,
            ws_ship_mode_sk AS store_key,
            ws_quantity AS quantity,
            CASE WHEN ws_quantity > 8 THEN 'Large' ELSE 'Small' END AS quantity_category,
            ROW_NUMBER() OVER (PARTITION BY ws_ship_mode_sk ORDER BY ws_quantity DESC) AS qty_rank,
            (SELECT COUNT(*) FROM store_sales WHERE ss_quantity > 0) AS total_sales_count
        FROM web_sales
        WHERE ws_quantity BETWEEN 4 AND 9
    )
SELECT ticket,
       store_key,
       quantity,
       quantity_category,
       qty_rank,
       total_return_amount
FROM final_set

UNION ALL

SELECT ticket,
       store_key,
       quantity,
       quantity_category,
       qty_rank,
       total_sales_count AS total_return_amount
FROM another_set

ORDER BY ticket
LIMIT 100
