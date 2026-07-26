WITH catalog_profit AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_quantity,
        SUM(cs.cs_ext_discount_amt) AS catalog_discount_sum
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY cs.cs_bill_customer_sk
),
web_profit AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_ext_discount_amt) AS web_discount_sum
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY ws.ws_bill_customer_sk
),
combined_profit AS (
    SELECT
        COALESCE(c.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(c.catalog_net_profit, 0) AS catalog_net_profit,
        COALESCE(w.web_net_profit, 0) AS web_net_profit,
        COALESCE(c.catalog_quantity, 0) AS catalog_quantity,
        COALESCE(w.web_quantity, 0) AS web_quantity,
        COALESCE(c.catalog_discount_sum, 0) AS catalog_discount_sum,
        COALESCE(w.web_discount_sum, 0) AS web_discount_sum,
        (COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0)) AS total_net_profit,
        (COALESCE(c.catalog_quantity, 0) + COALESCE(w.web_quantity, 0)) AS total_quantity,
        (COALESCE(c.catalog_discount_sum, 0) + COALESCE(w.web_discount_sum, 0)) AS total_discount_sum
    FROM catalog_profit c
    FULL OUTER JOIN web_profit w
        ON c.customer_sk = w.customer_sk
),
latest_time AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        MAX(cs.cs_sold_time_sk) AS max_time_sk
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk,
        MAX(ws.ws_sold_time_sk)
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
max_time_per_customer AS (
    SELECT
        customer_sk,
        MAX(max_time_sk) AS latest_time_sk
    FROM latest_time
    GROUP BY customer_sk
)
SELECT
    cp.customer_sk,
    cp.total_net_profit,
    cp.total_quantity,
    cp.total_discount_sum,
    CASE
        WHEN cp.total_net_profit > 50000 THEN 'VIP'
        WHEN cp.total_net_profit BETWEEN 10000 AND 50000 THEN 'PREMIUM'
        ELSE 'STANDARD'
    END AS customer_segment,
    RANK() OVER (ORDER BY cp.total_net_profit DESC) AS profit_rank,
    SUM(cp.total_net_profit) OVER (ORDER BY cp.total_net_profit DESC ROWS UNBOUNDED PRECEDING) AS cumulative_profit,
    t.t_hour AS latest_hour
FROM combined_profit cp
LEFT JOIN max_time_per_customer mt
    ON cp.customer_sk = mt.customer_sk
LEFT JOIN time_dim t
    ON mt.latest_time_sk = t.t_time_sk
WHERE cp.total_net_profit IS NOT NULL
ORDER BY profit_rank
LIMIT 20
