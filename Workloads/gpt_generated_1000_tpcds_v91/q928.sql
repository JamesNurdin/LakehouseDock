WITH sales_agg AS (
    SELECT
        ss_customer_sk,
        ss_promo_sk,
        ss_sold_time_sk,
        SUM(ss_net_paid)      AS total_net_paid,
        SUM(ss_net_profit)    AS total_net_profit,
        COUNT(*)              AS sales_txn_count
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_quantity > 0
    GROUP BY ss_customer_sk, ss_promo_sk, ss_sold_time_sk
)
SELECT
    p.p_promo_id,
    t_sales.t_hour,
    SUM(s.total_net_paid)                                   AS sum_net_paid,
    SUM(s.total_net_profit)                                 AS sum_net_profit,
    SUM(COALESCE(cr.cr_net_loss, 0))                        AS sum_catalog_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0))                        AS sum_web_return_loss,
    SUM(COALESCE(cr.cr_return_quantity, 0) + COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    SUM(pd.promo_discount_est)                              AS total_estimated_discount,
    COUNT(DISTINCT s.ss_customer_sk)                        AS distinct_customers
FROM sales_agg s
JOIN promotion p
    ON s.ss_promo_sk = p.p_promo_sk
JOIN customer cust
    ON s.ss_customer_sk = cust.c_customer_sk
JOIN customer_address addr
    ON cust.c_current_addr_sk = addr.ca_address_sk
JOIN time_dim t_sales
    ON s.ss_sold_time_sk = t_sales.t_time_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = cust.c_customer_sk
   AND cr.cr_refunded_addr_sk = addr.ca_address_sk
LEFT JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = cust.c_customer_sk
   AND wr.wr_refunded_addr_sk = addr.ca_address_sk
LEFT JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
CROSS JOIN LATERAL (
    SELECT CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost * 0.1 ELSE 0 END AS promo_discount_est
) AS pd
WHERE
    t_sales.t_hour BETWEEN 9 AND 18
    AND addr.ca_location_type = 'single family'
    AND p.p_discount_active = 'Y'
    AND s.total_net_paid > 500
GROUP BY p.p_promo_id, t_sales.t_hour
HAVING SUM(s.total_net_paid) > 10000
ORDER BY sum_net_paid DESC
LIMIT 100
