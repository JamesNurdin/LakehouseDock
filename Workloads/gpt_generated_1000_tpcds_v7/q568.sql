WITH aggregated AS (
    SELECT
        d.d_year,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        SUM(sr.sr_return_amt)            AS total_return_amt,
        SUM(sr.sr_return_quantity)       AS total_quantity,
        SUM(sr.sr_store_credit)          AS total_store_credit
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND sr.sr_return_quantity > 10
      AND ca.ca_state = 'TX'
    GROUP BY
        d.d_year,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state
)
SELECT
    d_year,
    c_customer_id,
    c_first_name,
    c_last_name,
    ca_state,
    total_return_amt,
    total_quantity,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC)        AS return_amt_rank,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_quantity DESC)   AS quantity_row_num,
    CASE 
        WHEN total_store_credit > 500 THEN 'High Credit'
        ELSE 'Normal Credit'
    END                                                                    AS credit_category
FROM aggregated
ORDER BY d_year, return_amt_rank
