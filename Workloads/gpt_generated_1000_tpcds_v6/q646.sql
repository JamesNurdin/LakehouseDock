WITH store_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_state,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
        CAST(NULL AS integer) AS web_return_count,
        SUM(sr.sr_return_amt) AS store_return_total,
        CAST(NULL AS decimal(7,2)) AS web_return_total,
        AVG(sr.sr_return_ship_cost) AS avg_ship_cost,
        CAST(NULL AS decimal(7,2)) AS avg_account_credit,
        MIN(sr.sr_return_amt_inc_tax) AS min_return_inc_tax,
        MAX(sr.sr_return_amt_inc_tax) AS max_return_inc_tax
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_birth_day BETWEEN 10 AND 20
      AND c.c_birth_month = 5
      AND c.c_first_sales_date_sk = 2451247
      AND sr.sr_store_credit > 50
      AND sr.sr_return_ship_cost < 50
      AND ca.ca_gmt_offset >= -5.00
    GROUP BY c.c_customer_sk, c.c_customer_id, ca.ca_state
    HAVING COUNT(sr.sr_ticket_number) > 1
),
web_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_state,
        CAST(NULL AS integer) AS store_return_count,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
        CAST(NULL AS decimal(7,2)) AS store_return_total,
        SUM(wr.wr_return_amt) AS web_return_total,
        CAST(NULL AS decimal(7,2)) AS avg_ship_cost,
        AVG(wr.wr_account_credit) AS avg_account_credit,
        MIN(wr.wr_return_amt_inc_tax) AS min_return_inc_tax,
        MAX(wr.wr_return_amt_inc_tax) AS max_return_inc_tax
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE c.c_birth_day = 15
      AND c.c_birth_month = 12
      AND c.c_first_sales_date_sk = 2452167
      AND wr.wr_refunded_cash > 200
      AND wr.wr_account_credit < 500
      AND ca.ca_state IN ('CA', 'NY')
    GROUP BY c.c_customer_sk, c.c_customer_id, ca.ca_state
    HAVING SUM(wr.wr_return_amt) > 1000
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT DISTINCT
    combined.c_customer_id,
    combined.ca_state,
    combined.store_return_count,
    combined.web_return_count,
    combined.store_return_total,
    combined.web_return_total,
    combined.avg_ship_cost,
    combined.avg_account_credit,
    combined.min_return_inc_tax,
    combined.max_return_inc_tax,
    RANK() OVER (PARTITION BY combined.ca_state ORDER BY (COALESCE(combined.store_return_total, 0) + COALESCE(combined.web_return_total, 0)) DESC) AS state_return_rank,
    (SELECT AVG(store_return_total) FROM store_agg) AS overall_avg_store_return
FROM combined
WHERE (combined.store_return_total IS NOT NULL AND combined.store_return_total > 500)
   OR (combined.web_return_total IS NOT NULL AND combined.web_return_total > 500)
  AND EXISTS (
        SELECT 1 FROM tpcds.store_returns sr_check
        WHERE sr_check.sr_customer_sk = combined.c_customer_sk
          AND sr_check.sr_return_amt > 100
    )
ORDER BY combined.ca_state, state_return_rank
LIMIT 100
