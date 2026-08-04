WITH ss_agg AS (
    SELECT
        ss_customer_sk,
        SUM(ss_net_paid) AS total_store_sales,
        COUNT(*) AS store_txn_count,
        MAX(ss_sold_date_sk) AS last_store_date_sk
    FROM store_sales
    WHERE ss_wholesale_cost > (SELECT AVG(ss_wholesale_cost) FROM store_sales)
    GROUP BY ss_customer_sk
),
ws_agg AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_web_sales,
        COUNT(*) AS web_txn_count,
        MAX(ws_sold_date_sk) AS last_web_date_sk
    FROM web_sales
    WHERE EXISTS (
        SELECT 1 FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = ws_ship_mode_sk
          AND sm.sm_code = 'AIR'
    )
    GROUP BY ws_bill_customer_sk
),
full_join AS (
    SELECT
        COALESCE(ss_agg.ss_customer_sk, ws_agg.customer_sk) AS customer_sk,
        ss_agg.total_store_sales,
        ws_agg.total_web_sales,
        ss_agg.store_txn_count,
        ws_agg.web_txn_count,
        ss_agg.last_store_date_sk,
        ws_agg.last_web_date_sk
    FROM ss_agg
    FULL OUTER JOIN ws_agg
        ON ss_agg.ss_customer_sk = ws_agg.customer_sk
),
first_part AS (
    SELECT
        fj.customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(fj.total_store_sales, 0) AS total_store_sales,
        COALESCE(fj.total_web_sales, 0) AS total_web_sales,
        COALESCE(fj.total_store_sales, 0) - COALESCE(fj.total_web_sales, 0) AS sales_diff,
        lt.latest_transaction_date
    FROM full_join fj
    LEFT JOIN customer c
        ON c.c_customer_sk = fj.customer_sk
    CROSS JOIN LATERAL (
        SELECT DATE '2023-01-01' + INTERVAL '1' DAY *
               GREATEST(COALESCE(fj.last_store_date_sk, 0), COALESCE(fj.last_web_date_sk, 0))
               AS latest_transaction_date
    ) lt
    WHERE (COALESCE(fj.total_store_sales,0) + COALESCE(fj.total_web_sales,0)) >
          (SELECT MAX(total_sales) FROM (
              SELECT SUM(ss_net_paid) AS total_sales FROM store_sales
              UNION ALL
              SELECT SUM(ws_net_paid) AS total_sales FROM web_sales
          ) agg)
),
second_part AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        0.0 AS total_store_sales,
        0.0 AS total_web_sales,
        0.0 AS sales_diff,
        NULL AS latest_transaction_date
    FROM customer c
    WHERE NOT EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk)
      AND NOT EXISTS (SELECT 1 FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
)
SELECT
    fp.customer_sk,
    fp.c_first_name,
    fp.c_last_name,
    fp.total_store_sales,
    fp.total_web_sales,
    fp.sales_diff,
    fp.latest_transaction_date
FROM first_part fp
UNION ALL
SELECT
    sp.customer_sk,
    sp.c_first_name,
    sp.c_last_name,
    sp.total_store_sales,
    sp.total_web_sales,
    sp.sales_diff,
    sp.latest_transaction_date
FROM second_part sp
ORDER BY sales_diff DESC
LIMIT 100
