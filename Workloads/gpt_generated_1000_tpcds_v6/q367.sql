WITH joined_data AS (
    SELECT
        cc.cc_name,
        cc.cc_state,
        d.d_year,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        c.c_customer_id
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 1917
      AND d.d_month_seq BETWEEN 2200 AND 2210
      AND inv.inv_warehouse_sk IN (13, 14)
      AND cc.cc_state = 'CA'
      AND sr.sr_return_amt > 100
)
SELECT
    cc_name,
    d_year,
    inv_warehouse_sk,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(sr_return_quantity) AS avg_return_quantity,
    MIN(inv_quantity_on_hand) AS min_quantity_on_hand,
    MAX(inv_quantity_on_hand) AS max_quantity_on_hand
FROM joined_data
GROUP BY
    cc_name,
    d_year,
    inv_warehouse_sk
ORDER BY total_return_amount DESC
LIMIT 100
