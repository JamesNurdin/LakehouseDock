WITH
    customer_current_address AS (
        SELECT
            c.c_customer_sk,
            ca.ca_address_sk,
            ca.ca_state,
            ca.ca_city,
            ca.ca_zip
        FROM customer c
        JOIN customer_address ca
            ON c.c_current_addr_sk = ca.ca_address_sk
    ),
    store_return_details AS (
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_customer_sk,
            sr.sr_addr_sk,
            sr.sr_store_sk,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_return_tax,
            sr.sr_return_amt_inc_tax,
            sr.sr_fee,
            sr.sr_return_ship_cost,
            sr.sr_refunded_cash,
            sr.sr_reversed_charge,
            sr.sr_store_credit,
            sr.sr_net_loss,
            ca.ca_state AS return_state,
            ca.ca_city AS return_city,
            ca.ca_zip AS return_zip
        FROM store_returns sr
        JOIN customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
    )
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca_cur.ca_state AS current_state,
    ca_cur.ca_city AS current_city,
    COUNT(DISTINCT sr.sr_store_sk) AS distinct_store_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_transactions
FROM customer c
JOIN customer_current_address ca_cur
    ON c.c_customer_sk = ca_cur.c_customer_sk
JOIN store_return_details sr
    ON c.c_customer_sk = sr.sr_customer_sk
WHERE sr.sr_return_amt > 0
GROUP BY
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca_cur.ca_state,
    ca_cur.ca_city
ORDER BY total_return_amount DESC
LIMIT 10
