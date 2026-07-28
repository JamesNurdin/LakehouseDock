WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_customer_sk,
        SUM(ss_net_profit) AS ss_total_profit,
        SUM(ss_ext_sales_price) AS ss_total_sales,
        COUNT(*) AS ss_txn_cnt
    FROM store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_store_sk, ss_customer_sk
)
SELECT
    cc.cc_call_center_id,
    c.c_customer_id,
    s.s_store_name,
    SUM(cs.cs_net_profit) AS catalog_profit,
    ss_agg.ss_total_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    CASE
        WHEN (SUM(cs.cs_net_profit) + ss_agg.ss_total_profit + SUM(ws.ws_net_profit)) > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END AS profit_level,
    (SELECT AVG(ss2.ss_net_profit)
     FROM store_sales ss2
     WHERE ss2.ss_store_sk = s.s_store_sk) AS avg_store_profit
FROM customer c
JOIN ss_agg
    ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN store s
    ON s.s_store_sk = ss_agg.ss_store_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN call_center cc
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE
    c.c_birth_year BETWEEN 1970 AND 1990
    AND s.s_floor_space > 8000000
    AND cc.cc_mkt_id IN (1, 3, 5)
    AND cs.cs_ship_customer_sk IN (4482187, 1612197)
    AND ws.ws_quantity > 2
GROUP BY
    cc.cc_call_center_id,
    c.c_customer_id,
    s.s_store_name,
    ss_agg.ss_total_profit,
    (SELECT AVG(ss2.ss_net_profit)
     FROM store_sales ss2
     WHERE ss2.ss_store_sk = s.s_store_sk)
ORDER BY
    profit_level DESC,
    catalog_profit DESC
LIMIT 100
