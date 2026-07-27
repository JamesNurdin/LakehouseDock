WITH refunded AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_zip,
        wr.wr_return_amt,
        wr.wr_returned_date_sk
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE c.c_salutation = 'Mr.'
      AND ca.ca_zip = '86192'
      AND wr.wr_web_page_sk = 1982
),
returning AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_zip,
        wr.wr_return_amt,
        wr.wr_returned_date_sk
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE c.c_salutation = 'Ms.'
      AND ca.ca_zip = '49843'
      AND wr.wr_web_page_sk = 1
),
combined AS (
    SELECT * FROM refunded
    UNION ALL
    SELECT * FROM returning
)
SELECT
    combined.c_customer_id,
    combined.c_first_name,
    combined.c_last_name,
    combined.ca_zip,
    combined.wr_return_amt,
    combined.wr_returned_date_sk,
    ROW_NUMBER() OVER (PARTITION BY combined.c_customer_id ORDER BY combined.wr_returned_date_sk DESC) AS rn
FROM combined
ORDER BY rn ASC, combined.wr_returned_date_sk DESC
LIMIT 100
