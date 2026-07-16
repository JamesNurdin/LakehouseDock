WITH
catalog_agg AS (
    SELECT
        c.c_birth_country AS birth_country,
        'catalog' AS channel,
        sm.sm_type AS ship_mode_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY c.c_birth_country, sm.sm_type
),
web_agg AS (
    SELECT
        c.c_birth_country AS birth_country,
        'web' AS channel,
        sm.sm_type AS ship_mode_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY c.c_birth_country, sm.sm_type
),
store_sales_agg AS (
    SELECT
        c.c_birth_country AS birth_country,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY c.c_birth_country
),
store_returns_agg AS (
    SELECT
        c.c_birth_country AS birth_country,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY c.c_birth_country
),
store_agg_adj AS (
    SELECT
        ss.birth_country,
        'store' AS channel,
        NULL AS ship_mode_type,
        (ss.total_net_profit - COALESCE(sr.total_return_loss, 0)) AS total_net_profit,
        ss.total_quantity,
        ss.avg_discount
    FROM store_sales_agg ss
    LEFT JOIN store_returns_agg sr ON ss.birth_country = sr.birth_country
)
SELECT
    birth_country,
    channel,
    ship_mode_type,
    total_net_profit,
    total_quantity,
    avg_discount
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
    UNION ALL
    SELECT * FROM store_agg_adj
) AS agg
WHERE total_net_profit > 0
ORDER BY total_net_profit DESC
LIMIT 20
