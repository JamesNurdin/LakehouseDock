WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ss.ss_net_paid)                         AS store_net_paid,
        SUM(ws.ws_net_paid_inc_ship)                AS web_net_paid,
        COUNT(DISTINCT ss.ss_item_sk)                AS distinct_store_items,
        COUNT(DISTINCT ws.ws_item_sk)                AS distinct_web_items,
        hd.hd_income_band_sk                         AS income_band_sk
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_sales ws
        ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_month IN (1, 2, 4, 12)                      -- predicate 1
      AND ss.ss_wholesale_cost > 20.00                         -- predicate 2
      AND ws.ws_sold_time_sk BETWEEN 10000 AND 80000          -- predicate 3
      AND ss.ss_quantity >= 1                                 -- predicate 4
    GROUP BY c.c_customer_sk, c.c_customer_id, hd.hd_income_band_sk
),
return_agg AS (
    SELECT
        cr.cr_returning_customer_sk            AS cust_sk,
        COUNT(*)                               AS return_count,
        SUM(cr.cr_return_amount)               AS total_return_amount,
        SUM(CASE WHEN cr.cr_return_amount > 100 THEN 1 ELSE 0 END) AS high_value_returns
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 0                           -- predicate 5
      AND cr.cr_return_quantity > 0                         -- predicate 6
    GROUP BY cr.cr_returning_customer_sk
)
SELECT
    s.c_customer_id,
    s.store_net_paid,
    s.web_net_paid,
    (s.store_net_paid + s.web_net_paid)                     AS total_net_paid,
    r.return_count,
    r.total_return_amount,
    CASE WHEN r.high_value_returns > 0 THEN 'HAS_HIGH' ELSE 'NO_HIGH' END AS high_return_flag,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT r2.r_reason_id) OVER (PARTITION BY s.c_customer_id) AS distinct_return_reasons,
    SUM(DISTINCT cr2.cr_fee) OVER (PARTITION BY s.c_customer_id)       AS sum_distinct_return_fees,
    ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY (s.store_net_paid + s.web_net_paid) DESC) AS rank_within_income_band
FROM sales_agg s
LEFT JOIN return_agg r
    ON s.c_customer_sk = r.cust_sk
LEFT JOIN catalog_returns cr2
    ON cr2.cr_returning_customer_sk = s.c_customer_sk
LEFT JOIN reason r2
    ON cr2.cr_reason_sk = r2.r_reason_sk
LEFT JOIN income_band ib
    ON s.income_band_sk = ib.ib_income_band_sk
WHERE s.c_customer_id NOT IN (
        SELECT c3.c_customer_id
        FROM customer c3
        WHERE c3.c_email_address LIKE '%@test.org%'
    )
  AND ib.ib_lower_bound > 20000                               -- predicate 7
  AND ib.ib_upper_bound < 100000                               -- predicate 8
LIMIT 100
