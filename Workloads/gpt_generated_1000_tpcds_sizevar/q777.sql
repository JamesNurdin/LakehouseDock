WITH sampled_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    customers_jan AS (
        SELECT c.c_customer_sk
        FROM sampled_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE d.d_month_seq = 120 -- January 2001 (example)
        GROUP BY c.c_customer_sk
        HAVING SUM(ss.ss_net_profit) > 1000
    ),
    customers_feb AS (
        SELECT c.c_customer_sk
        FROM sampled_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE d.d_month_seq = 121 -- February 2001 (example)
        GROUP BY c.c_customer_sk
        HAVING SUM(ss.ss_net_profit) > 1000
    ),
    common_customers AS (
        SELECT c_sk
        FROM (
            SELECT c_customer_sk AS c_sk FROM customers_jan
            INTERSECT
            SELECT c_customer_sk AS c_sk FROM customers_feb
        )
    )
SELECT
    d.d_year,
    d.d_month_seq,
    c.c_customer_id,
    ss.ss_ticket_number,
    ss.ss_quantity,
    ss.ss_net_profit,
    ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk, d.d_month_seq ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    p.p_promo_name,
    iq.total_qty,
    CASE WHEN cr.cr_return_quantity IS NULL THEN 'No Return' ELSE 'Returned' END AS return_flag
FROM sampled_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
FULL OUTER JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
CROSS JOIN LATERAL (
    SELECT SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory i2
    WHERE i2.inv_item_sk = p.p_item_sk
      AND i2.inv_date_sk = d.d_date_sk
) iq
WHERE
    d.d_year = 2001
    AND ss.ss_quantity > 1
    AND p.p_channel_tv = 'N'
    AND ss.ss_net_profit > 0
    AND i.inv_quantity_on_hand > 0
    AND c.c_customer_sk IN (SELECT c_sk FROM common_customers)
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = ss.ss_sold_date_sk
          AND cr2.cr_order_number = ss.ss_ticket_number
    )
ORDER BY d.d_year, d.d_month_seq, profit_rank
LIMIT 100
