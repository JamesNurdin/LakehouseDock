/*
  Goal: Analyze net sales, returns and profit by US state and income band, showing subtotals and a grand total, while applying multiple filters, a sample of sales data, and a deduplication step via UNION.
*/
WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_return_amt,
        c.c_customer_id,
        ca.ca_state,
        ca.ca_country,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of store_sales rows
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk
       AND ss.ss_customer_sk = sr.sr_customer_sk
),
agg AS (
    SELECT
        ca_state,
        ib_lower_bound,
        ib_upper_bound,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(sr_return_amt) AS total_returns,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS num_transactions
    FROM base
    WHERE ca_country = 'United States'                 -- filter 1
      AND ib_lower_bound >= 30000                     -- filter 2
      AND hd_dep_count <= 5                           -- filter 3
      AND ss_sold_date_sk BETWEEN 2450000 AND 2451000 -- filter 4 (surrogate date range)
    GROUP BY ROLLUP (ca_state, ib_lower_bound, ib_upper_bound)
    HAVING SUM(ss_ext_sales_price) > 10000
)
SELECT
    ca_state,
    ib_lower_bound,
    ib_upper_bound,
    total_sales,
    total_returns,
    total_profit,
    num_transactions
FROM agg
UNION DISTINCT
SELECT
    ca_state,
    ib_lower_bound,
    ib_upper_bound,
    total_sales,
    total_returns,
    total_profit,
    num_transactions
FROM agg
WHERE total_profit > 0
  AND EXISTS (
        SELECT 1
        FROM agg a2
        WHERE a2.ca_state = agg.ca_state
          AND a2.total_sales > agg.total_sales
    )
ORDER BY ca_state, ib_lower_bound
LIMIT 100
