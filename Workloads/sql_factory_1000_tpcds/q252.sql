WITH catalog_profit AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_txn_cnt,
        AVG(cs.cs_quantity) AS avg_catalog_quantity
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y' AND cs.cs_sold_date_sk >= 20000101
    GROUP BY cs.cs_bill_customer_sk
),
web_profit AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_txn_cnt,
        AVG(ws.ws_quantity) AS avg_web_quantity
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y' AND ws.ws_sold_date_sk >= 20000101
    GROUP BY ws.ws_bill_customer_sk
),
combined_profit AS (
    SELECT
        COALESCE(c.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(c.catalog_net_profit, 0) AS catalog_net_profit,
        COALESCE(w.web_net_profit, 0) AS web_net_profit,
        COALESCE(c.catalog_txn_cnt, 0) AS catalog_txn_cnt,
        COALESCE(w.web_txn_cnt, 0) AS web_txn_cnt,
        (COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0)) AS total_net_profit,
        (COALESCE(c.catalog_txn_cnt, 0) + COALESCE(w.web_txn_cnt, 0)) AS total_txn_cnt,
        (COALESCE(c.avg_catalog_quantity, 0) + COALESCE(w.avg_web_quantity, 0)) / 2 AS avg_quantity
    FROM catalog_profit c
    FULL OUTER JOIN web_profit w ON c.customer_sk = w.customer_sk
),
latest_time AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk, MAX(cs.cs_sold_time_sk) AS max_time_sk
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk
    UNION ALL
    SELECT ws.ws_bill_customer_sk, MAX(ws.ws_sold_time_sk)
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
max_time_per_customer AS (
    SELECT customer_sk, MAX(max_time_sk) AS latest_time_sk
    FROM latest_time
    GROUP BY customer_sk
)
SELECT
    cp.customer_sk,
    cp.total_net_profit,
    cp.total_txn_cnt,
    cp.avg_quantity,
    CASE WHEN cp.total_net_profit > 80000 THEN 'PLATINUM' WHEN cp.total_net_profit > 40000 THEN 'GOLD' ELSE 'SILVER' END AS tier,
    ROW_NUMBER() OVER (ORDER BY cp.total_net_profit DESC) AS profit_rank,
    SUM(cp.total_net_profit) OVER (ORDER BY cp.total_net_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    t.t_hour AS latest_hour
FROM combined_profit cp
LEFT JOIN max_time_per_customer mt ON cp.customer_sk = mt.customer_sk
LEFT JOIN time_dim t ON mt.latest_time_sk = t.t_time_sk
WHERE cp.total_net_profit IS NOT NULL
ORDER BY profit_rank
LIMIT 10
