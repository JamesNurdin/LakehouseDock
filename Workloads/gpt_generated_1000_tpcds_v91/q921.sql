WITH catalog_ret AS (
    SELECT
        c.c_customer_id AS customer_id,
        ca.ca_state AS state,
        i.i_item_id AS item_id,
        cr.cr_return_amt_inc_tax AS return_amount,
        CASE
            WHEN cr.cr_return_amt_inc_tax > 1000 THEN 'High'
            WHEN cr.cr_return_amt_inc_tax > 500 THEN 'Medium'
            ELSE 'Low'
        END AS return_severity,
        (
            SELECT AVG(cr2.cr_return_amt_inc_tax)
            FROM catalog_returns cr2
            JOIN customer c2 ON cr2.cr_refunded_customer_sk = c2.c_customer_sk
            JOIN customer_address ca2 ON cr2.cr_refunded_addr_sk = ca2.ca_address_sk
            WHERE ca2.ca_state = ca.ca_state
        ) AS avg_state_return_amount,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM web_sales ws
                WHERE ws.ws_bill_customer_sk = c.c_customer_sk
                  AND ws.ws_item_sk = i.i_item_sk
            ) THEN 1 ELSE 0
        END AS has_web_purchase
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amt_inc_tax > 100
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr WHERE sr.sr_item_sk = i.i_item_sk
      )
),
web_ret AS (
    SELECT
        c.c_customer_id AS customer_id,
        ca.ca_state AS state,
        i.i_item_id AS item_id,
        wr.wr_return_amt_inc_tax AS return_amount,
        CASE
            WHEN wr.wr_return_amt_inc_tax > 1000 THEN 'High'
            WHEN wr.wr_return_amt_inc_tax > 500 THEN 'Medium'
            ELSE 'Low'
        END AS return_severity,
        (
            SELECT AVG(wr2.wr_return_amt_inc_tax)
            FROM web_returns wr2
            JOIN customer c2 ON wr2.wr_refunded_customer_sk = c2.c_customer_sk
            JOIN customer_address ca2 ON wr2.wr_refunded_addr_sk = ca2.ca_address_sk
            WHERE ca2.ca_state = ca.ca_state
        ) AS avg_state_return_amount,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM web_sales ws
                WHERE ws.ws_bill_customer_sk = c.c_customer_sk
                  AND ws.ws_item_sk = i.i_item_sk
            ) THEN 1 ELSE 0
        END AS has_web_purchase
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_return_amt_inc_tax > 100
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr WHERE sr.sr_item_sk = i.i_item_sk
      )
)
SELECT
    customer_id,
    state,
    item_id,
    return_amount,
    return_severity,
    avg_state_return_amount,
    has_web_purchase
FROM catalog_ret
UNION
SELECT
    customer_id,
    state,
    item_id,
    return_amount,
    return_severity,
    avg_state_return_amount,
    has_web_purchase
FROM web_ret
ORDER BY return_amount DESC
LIMIT 100
