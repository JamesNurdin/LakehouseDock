WITH store_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        SUM(ss.ss_ext_sales_price) AS store_ext_sales,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    WHERE ss.ss_sales_price > 10
    GROUP BY ss.ss_store_sk, ss.ss_hdemo_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    ss_agg.store_ext_sales,
    ss_agg.store_net_profit,
    ws.ws_net_profit AS web_net_profit,
    wr.wr_return_amt,
    (
        SELECT AVG(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_returning_hdemo_sk = hd.hd_demo_sk
    ) AS avg_return_amt_for_hh,
    CASE
        WHEN hd.hd_vehicle_count > 2 THEN 'High Vehicle'
        ELSE 'Low Vehicle'
    END AS vehicle_category,
    (ss_agg.store_net_profit + ws.ws_net_profit) AS combined_profit,
    DENSE_RANK() OVER (ORDER BY (ss_agg.store_net_profit + ws.ws_net_profit) DESC) AS profit_rank,
    SUM(ss_agg.store_net_profit + ws.ws_net_profit) OVER (
        PARTITION BY s.s_store_sk
        ORDER BY ws.ws_order_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_profit
FROM store_sales_agg ss_agg
JOIN household_demographics hd
    ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON ss_agg.ss_store_sk = s.s_store_sk
JOIN web_sales ws
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
WHERE
    s.s_country = 'United States'
    AND s.s_state = 'CA'
    AND s.s_rec_start_date >= DATE '1999-01-01'
    AND hd.hd_vehicle_count >= 1
    AND hd.hd_dep_count BETWEEN 2 AND 6
    AND ws.ws_net_profit > 0
    AND wr.wr_return_amt > 50
    AND ss_agg.store_ext_sales > 1000
    AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_amt > 100
    )
ORDER BY profit_rank
LIMIT 100
