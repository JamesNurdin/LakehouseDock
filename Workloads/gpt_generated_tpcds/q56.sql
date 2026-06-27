/*
  Top‑3 customers by total net loss within each state.
  The query aggregates store return losses per customer, joins the
  customer's current address to obtain the state, then ranks customers
  per state using ROW_NUMBER().
*/
WITH customer_returns AS (
    SELECT
        c.c_customer_id,
        ca_cur.ca_state AS cust_state,
        SUM(sr.sr_net_loss)          AS total_net_loss,
        SUM(sr.sr_return_quantity)   AS total_quantity,
        SUM(sr.sr_return_amt)        AS total_return_amt
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca_cur
        ON c.c_current_addr_sk = ca_cur.ca_address_sk
    WHERE sr.sr_net_loss > 0
    GROUP BY c.c_customer_id, ca_cur.ca_state
),
ranked_customers AS (
    SELECT
        cust_state,
        c_customer_id,
        total_net_loss,
        total_quantity,
        total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY cust_state ORDER BY total_net_loss DESC) AS rn
    FROM customer_returns
)
SELECT
    cust_state,
    c_customer_id,
    total_net_loss,
    total_quantity,
    total_return_amt
FROM ranked_customers
WHERE rn <= 3
ORDER BY cust_state, total_net_loss DESC
