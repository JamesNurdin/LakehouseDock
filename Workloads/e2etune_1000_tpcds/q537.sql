WITH profit_by_mode AS (
    SELECT
        sm.sm_carrier,
        sm.sm_type,
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_net_paid) AS total_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM ship_mode sm
    JOIN store_sales ss
        ON sm.sm_ship_mode_sk = ss.ss_store_sk
    WHERE sm.sm_contract LIKE 'Y%'
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY sm.sm_carrier, sm.sm_type, ss.ss_store_sk
)
SELECT
    sm_carrier,
    sm_type,
    ss_store_sk,
    total_profit,
    total_paid,
    avg_discount,
    RANK() OVER (PARTITION BY ss_store_sk ORDER BY total_profit DESC) AS profit_rank
FROM profit_by_mode
WHERE total_profit > 1000
ORDER BY ss_store_sk, profit_rank
