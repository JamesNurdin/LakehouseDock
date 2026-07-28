WITH store_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN time_dim td_store ON ss.ss_sold_time_sk = td_store.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE td_store.t_hour >= 12
      AND ss.ss_quantity >= 2
      AND ca.ca_location_type = 'condo'
      AND hd.hd_income_band_sk >= 10
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        hd.hd_income_band_sk
),
web_agg AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN time_dim td_web ON ws.ws_sold_time_sk = td_web.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE td_web.t_hour >= 12
      AND ws.ws_ext_tax > 30
      AND ca.ca_location_type = 'condo'
      AND hd.hd_income_band_sk >= 10
    GROUP BY c.c_customer_sk
)
SELECT
    s.c_customer_id,
    s.ca_city,
    s.ca_state,
    s.hd_income_band_sk,
    s.store_net_paid,
    w.web_net_paid,
    (s.store_net_paid + w.web_net_paid) AS total_net_paid,
    (s.store_net_profit + w.web_net_profit) / (s.store_txn_cnt + w.web_txn_cnt) AS avg_net_profit,
    RANK() OVER (PARTITION BY s.ca_state ORDER BY (s.store_net_paid + w.web_net_paid) DESC) AS state_rank,
    CASE
        WHEN (s.store_net_profit + w.web_net_profit) / (s.store_txn_cnt + w.web_txn_cnt) > (
            SELECT AVG(profit)
            FROM (
                SELECT ss.ss_net_profit AS profit FROM store_sales ss
                UNION ALL
                SELECT ws.ws_net_profit FROM web_sales ws
            ) p
        ) THEN 'Above Avg Profit'
        ELSE 'Below Avg Profit'
    END AS profit_comp
FROM store_agg s
JOIN web_agg w ON s.c_customer_sk = w.c_customer_sk
ORDER BY total_net_paid DESC
LIMIT 100
