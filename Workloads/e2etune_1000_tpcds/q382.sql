WITH state_metrics AS (
    SELECT
        ca.ca_state AS state,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss,
        SUM(ss.ss_quantity) AS total_quantity,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_quantity
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_address ca_cur ON c.c_current_addr_sk = ca_cur.ca_address_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk
       AND ss.ss_customer_sk = sr.sr_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_month = 7
      AND ca.ca_country = 'United States'
      AND ca_cur.ca_country = 'United States'
      AND ca.ca_state = ca_cur.ca_state
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY ca.ca_state
)
SELECT
    state,
    num_transactions,
    total_sales,
    total_profit,
    total_return_amount,
    total_return_loss,
    (total_sales - total_return_amount) AS net_sales,
    (total_profit - total_return_loss) AS net_profit,
    (total_quantity - total_return_quantity) AS net_quantity,
    ROUND(CASE WHEN total_quantity = 0 THEN 0 ELSE total_return_quantity * 1.0 / total_quantity END, 4) AS return_rate,
    RANK() OVER (ORDER BY (total_profit - total_return_loss) DESC) AS profit_rank
FROM state_metrics
WHERE (total_sales - total_return_amount) > 10000
ORDER BY net_profit DESC
LIMIT 20
