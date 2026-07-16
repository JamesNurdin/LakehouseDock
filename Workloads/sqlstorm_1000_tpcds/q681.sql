WITH
catalog_agg AS (
    SELECT
        cs_bill_customer_sk AS cust_sk,
        SUM(cs_net_profit) AS catalog_profit,
        SUM(cs_quantity) AS catalog_quantity,
        COUNT(DISTINCT cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs_bill_customer_sk
),
store_agg AS (
    SELECT
        ss_customer_sk AS cust_sk,
        SUM(ss_net_profit) AS store_profit,
        SUM(ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss_ticket_number) AS store_orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss_customer_sk
),
web_agg AS (
    SELECT
        ws_bill_customer_sk AS cust_sk,
        SUM(ws_net_profit) AS web_profit,
        SUM(ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws_bill_customer_sk
),
combined AS (
    SELECT
        COALESCE(ca.cust_sk, sa.cust_sk, wa.cust_sk) AS cust_sk,
        ca.catalog_profit,
        ca.catalog_quantity,
        ca.catalog_orders,
        sa.store_profit,
        sa.store_quantity,
        sa.store_orders,
        wa.web_profit,
        wa.web_quantity,
        wa.web_orders
    FROM catalog_agg ca
    FULL OUTER JOIN store_agg sa ON ca.cust_sk = sa.cust_sk
    FULL OUTER JOIN web_agg wa ON COALESCE(ca.cust_sk, sa.cust_sk) = wa.cust_sk
),
customer_detail AS (
    SELECT
        c.c_customer_sk,
        CONCAT(UPPER(c.c_first_name), ' ', UPPER(c.c_last_name)) AS full_name,
        COALESCE(c.c_preferred_cust_flag, 'N') AS preferred_flag,
        CASE
            WHEN c.c_birth_year IS NULL THEN 'UNKNOWN'
            WHEN c.c_birth_year < 1950 THEN 'SENIOR'
            ELSE 'ADULT'
        END AS age_group,
        COALESCE(cc.cc_name, 'UNKNOWN_CC') AS call_center_name
    FROM customer c
    LEFT JOIN call_center cc ON c.c_customer_sk = cc.cc_call_center_sk
    WHERE c.c_current_addr_sk IS NOT NULL
),
ranked_customers AS (
    SELECT
        cd.c_customer_sk,
        cd.full_name,
        cd.preferred_flag,
        cd.age_group,
        cd.call_center_name,
        COALESCE(comb.catalog_profit, 0) + COALESCE(comb.store_profit, 0) + COALESCE(comb.web_profit, 0) AS total_profit,
        COALESCE(comb.catalog_quantity, 0) + COALESCE(comb.store_quantity, 0) + COALESCE(comb.web_quantity, 0) AS total_quantity,
        ROW_NUMBER() OVER (ORDER BY COALESCE(comb.catalog_profit, 0) + COALESCE(comb.store_profit, 0) + COALESCE(comb.web_profit, 0) DESC) AS profit_rank,
        (SELECT AVG(sub.total_profit)
         FROM (
           SELECT
               COALESCE(c2.catalog_profit, 0) + COALESCE(s2.store_profit, 0) + COALESCE(w2.web_profit, 0) AS total_profit
           FROM combined c2
           LEFT JOIN catalog_agg ca2 ON c2.cust_sk = ca2.cust_sk
           LEFT JOIN store_agg s2 ON c2.cust_sk = s2.cust_sk
           LEFT JOIN web_agg w2 ON c2.cust_sk = w2.cust_sk
           WHERE c2.cust_sk = comb.cust_sk
         ) sub) AS avg_profit_per_customer
    FROM combined comb
    INNER JOIN customer_detail cd ON cd.c_customer_sk = comb.cust_sk
    WHERE (COALESCE(comb.catalog_profit,0) + COALESCE(comb.store_profit,0) + COALESCE(comb.web_profit,0)) > 1000
      AND cd.preferred_flag = 'Y'
),
final_active AS (
    SELECT
        rc.c_customer_sk,
        rc.full_name,
        rc.age_group,
        rc.call_center_name,
        rc.total_profit,
        rc.total_quantity,
        CASE
            WHEN rc.total_quantity = 0 THEN NULL
            ELSE rc.total_profit / rc.total_quantity
        END AS profit_per_item,
        CASE
            WHEN rc.profit_rank <= 10 THEN 'TOP10'
            WHEN rc.profit_rank <= 50 THEN 'TOP50'
            ELSE 'OTHER'
        END AS tier,
        rc.profit_rank
    FROM ranked_customers rc
    WHERE rc.profit_rank <= 100
),
final_inactive AS (
    SELECT
        cd.c_customer_sk,
        cd.full_name,
        cd.age_group,
        cd.call_center_name,
        0.0 AS total_profit,
        0 AS total_quantity,
        CAST(NULL AS double) AS profit_per_item,
        'INACTIVE' AS tier,
        NULL AS profit_rank
    FROM customer_detail cd
    LEFT JOIN combined comb ON cd.c_customer_sk = comb.cust_sk
    WHERE cd.preferred_flag = 'Y' AND comb.cust_sk IS NULL
)
SELECT
    fu.c_customer_sk,
    fu.full_name,
    fu.age_group,
    fu.call_center_name,
    fu.total_profit,
    fu.total_quantity,
    fu.profit_per_item,
    fu.tier,
    COALESCE(NULLIF(fu.profit_per_item, 0), 0) * 1.05 AS adjusted_profit_per_item,
    CASE
        WHEN fu.tier = 'TOP10' THEN 'Gold'
        WHEN fu.tier = 'TOP50' THEN 'Silver'
        WHEN fu.tier = 'INACTIVE' THEN 'None'
        ELSE 'Bronze'
    END AS loyalty_level,
    SUBSTRING(fu.full_name FROM 1 FOR 3) AS name_prefix,
    (SELECT COALESCE(AVG(cs.cs_sales_price), 0)
     FROM catalog_sales cs
     WHERE cs.cs_bill_customer_sk = fu.c_customer_sk) AS avg_catalog_sales_price,
    fu.profit_rank
FROM (
    SELECT * FROM final_active
    UNION ALL
    SELECT * FROM final_inactive
) fu
ORDER BY fu.profit_rank NULLS LAST, fu.total_profit DESC
LIMIT 150
