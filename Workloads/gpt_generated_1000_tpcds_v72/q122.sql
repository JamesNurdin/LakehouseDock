WITH sr AS (
    SELECT 
        sr_returned_date_sk,
        sr_customer_sk,
        sr_store_sk,
        sr_reason_sk,
        sr_return_amt,
        sr_return_quantity,
        sr_net_loss
    FROM store_returns
    WHERE sr_return_amt > 1000
)
SELECT
    s.s_state,
    c.c_birth_month,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    COUNT(*) AS return_count,
    MAX(sr.sr_return_amt) AS max_return_amount,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN sr.sr_return_amt ELSE 0 END) AS preferred_return_amount,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand
FROM sr
JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN inventory i ON i.inv_date_sk = d_ret.d_date_sk
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE
    d_ret.d_year = 2001
    AND c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_month = 7
    AND s.s_state = 'CA'
    AND w.w_state = 'CA'
    AND i.inv_quantity_on_hand > 100
    AND cp.cp_type = 'PROMO'
    AND wp.wp_type = 'CONTENT'
GROUP BY ROLLUP (s.s_state, c.c_birth_month)
ORDER BY total_return_amount DESC
LIMIT 100
