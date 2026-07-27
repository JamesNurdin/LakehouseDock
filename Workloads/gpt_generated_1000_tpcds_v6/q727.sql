/*
Goal: Calculate per‑customer sales performance, total catalog and web return losses, and rank customers by sales while filtering on demographic and transaction criteria.
*/
WITH customer_sales AS (
    SELECT
        c.c_customer_sk        AS customer_sk,
        c.c_customer_id,
        ca.ca_state,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_sales_price)      AS avg_sales_price,
        COUNT(*)                    AS cnt_sales,
        SUM(ss.ss_net_profit)       AS total_profit
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000               -- sold date range
      AND c.c_birth_year = 1980                                         -- birth year filter
      AND c.c_salutation = 'Mr.'                                        -- salutation filter
      AND ca.ca_state = 'CA'                                            -- state filter
    GROUP BY c.c_customer_sk, c.c_customer_id, ca.ca_state
),
catalog_ret_agg AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        SUM(cr.cr_net_loss)        AS total_return_loss,
        COUNT(*)                   AS cnt_cr
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_tax > 20.00            -- return tax filter
      AND cr.cr_return_quantity >= 1
    GROUP BY cr.cr_refunded_customer_sk
),
web_ret_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        SUM(wr.wr_net_loss)        AS total_web_loss,
        COUNT(*)                   AS cnt_wr
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_return_tax < 5.00            -- return tax filter
      AND wr.wr_return_quantity > 0
    GROUP BY wr.wr_refunded_customer_sk
),
overall_sales AS (
    SELECT SUM(ss.ss_ext_sales_price) AS total_sales_all
    FROM store_sales ss
)
SELECT
    cs.c_customer_id,
    cs.ca_state,
    cs.total_sales,
    cs.avg_sales_price,
    COALESCE(cr.total_return_loss, 0) AS total_return_loss,
    COALESCE(wr.total_web_loss, 0)    AS total_web_loss,
    cs.total_sales + COALESCE(cr.total_return_loss, 0) + COALESCE(wr.total_web_loss, 0) AS net_amount,
    RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
    cs.total_sales / os.total_sales_all          AS sales_share
FROM customer_sales cs
LEFT JOIN catalog_ret_agg cr
    ON cs.customer_sk = cr.customer_sk
LEFT JOIN web_ret_agg wr
    ON cs.customer_sk = wr.customer_sk
CROSS JOIN overall_sales os
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_refunded_customer_sk = cs.customer_sk
      AND cr2.cr_return_amount > 100.00   -- high‑value return filter
)
ORDER BY net_amount DESC
LIMIT 100
