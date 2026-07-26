WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_country,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_birth_country
),
customer_pages AS (
    SELECT
        wp.wp_customer_sk AS c_customer_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS page_visits
    FROM web_page wp
    GROUP BY wp.wp_customer_sk
),
customer_warehouse AS (
    SELECT
        c.c_customer_sk,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS profit_by_warehouse
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY c.c_customer_sk, w.w_warehouse_name
),
top_warehouse AS (
    SELECT
        cw.c_customer_sk,
        cw.w_warehouse_name,
        ROW_NUMBER() OVER (PARTITION BY cw.c_customer_sk ORDER BY cw.profit_by_warehouse DESC) AS rn
    FROM customer_warehouse cw
)
SELECT
    cs.c_customer_id,
    cs.c_birth_country,
    cs.total_net_profit,
    cs.total_net_paid,
    cs.order_cnt,
    cp.page_visits,
    CASE
        WHEN cs.total_net_profit > 50000 THEN 'VIP'
        WHEN cs.total_net_profit > 20000 THEN 'PREMIUM'
        ELSE 'STANDARD'
    END AS customer_tier,
    tw.w_warehouse_name AS top_warehouse,
    DENSE_RANK() OVER (PARTITION BY cs.c_birth_country ORDER BY cs.total_net_profit DESC) AS country_profit_rank
FROM customer_sales cs
LEFT JOIN customer_pages cp ON cs.c_customer_sk = cp.c_customer_sk
LEFT JOIN top_warehouse tw ON cs.c_customer_sk = tw.c_customer_sk AND tw.rn = 1
WHERE cs.order_cnt >= 5
ORDER BY cs.total_net_profit DESC
LIMIT 100
