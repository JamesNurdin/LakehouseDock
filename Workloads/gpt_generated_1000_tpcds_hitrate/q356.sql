WITH
sales_part AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        COUNT(DISTINCT hd.hd_vehicle_count) AS distinct_vehicle_cnt,
        COUNT(DISTINCT ss.ss_store_sk) AS distinct_store_cnt,
        SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_profit ELSE 0 END) AS total_positive_profit
    FROM store_sales ss
    FULL OUTER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = '1001-5000'
      AND ss.ss_wholesale_cost > 20
    GROUP BY hd.hd_demo_sk
),
returns_part AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        COUNT(DISTINCT sr.sr_store_credit) AS distinct_store_credit_cnt,
        COUNT(DISTINCT sr.sr_return_amt_inc_tax) AS distinct_return_amt_inc_tax_cnt,
        SUM(CASE WHEN sr.sr_return_tax > 10 THEN sr.sr_return_tax ELSE 0 END) AS sum_return_tax_gt10
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE sr.sr_return_amt_inc_tax > 150
      AND hd.hd_vehicle_count >= 2
    GROUP BY hd.hd_demo_sk
)
SELECT
    demo_sk,
    distinct_vehicle_cnt,
    distinct_store_cnt,
    total_positive_profit,
    NULL AS distinct_store_credit_cnt,
    NULL AS sum_return_tax_gt10,
    NULL AS distinct_return_amt_inc_tax_cnt
FROM sales_part
UNION ALL
SELECT
    demo_sk,
    NULL AS distinct_vehicle_cnt,
    NULL AS distinct_store_cnt,
    NULL AS total_positive_profit,
    distinct_store_credit_cnt,
    sum_return_tax_gt10,
    distinct_return_amt_inc_tax_cnt
FROM returns_part
ORDER BY demo_sk
LIMIT 100
