WITH
store_agg AS (
    SELECT
        c.c_customer_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        MAX(p.p_promo_name) AS store_top_promo
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_sk
),
catalog_agg AS (
    SELECT
        c.c_customer_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions,
        MAX(p.p_promo_name) AS catalog_top_promo
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_sk
),
web_agg AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
        MAX(p.p_promo_name) AS web_top_promo
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_sk
),
customers_store AS (
    SELECT DISTINCT ss.ss_customer_sk AS c_customer_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
),
customers_catalog AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS c_customer_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
),
customers_web AS (
    SELECT DISTINCT ws.ws_bill_customer_sk AS c_customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
),
customers_all_channels AS (
    SELECT c_customer_sk FROM customers_store
    INTERSECT
    SELECT c_customer_sk FROM customers_catalog
    INTERSECT
    SELECT c_customer_sk FROM customers_web
),
latest_address AS (
    SELECT
        ca.c_customer_sk,
        ca_addr.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.c_customer_sk ORDER BY ca.c_current_addr_sk DESC) AS rn
    FROM customer ca
    LEFT JOIN customer_address ca_addr ON ca.c_current_addr_sk = ca_addr.ca_address_sk
),
combined AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        la.ca_state AS state,
        COALESCE(s.store_net_profit, 0) AS store_net_profit,
        COALESCE(s.store_quantity, 0) AS store_quantity,
        COALESCE(s.store_transactions, 0) AS store_transactions,
        COALESCE(s.store_top_promo, '') AS store_top_promo,
        COALESCE(cat.catalog_net_profit, 0) AS catalog_net_profit,
        COALESCE(cat.catalog_quantity, 0) AS catalog_quantity,
        COALESCE(cat.catalog_transactions, 0) AS catalog_transactions,
        COALESCE(cat.catalog_top_promo, '') AS catalog_top_promo,
        COALESCE(w.web_net_profit, 0) AS web_net_profit,
        COALESCE(w.web_quantity, 0) AS web_quantity,
        COALESCE(w.web_transactions, 0) AS web_transactions,
        COALESCE(w.web_top_promo, '') AS web_top_promo,
        (COALESCE(s.store_net_profit,0) + COALESCE(cat.catalog_net_profit,0) + COALESCE(w.web_net_profit,0)) AS total_net_profit
    FROM customers_all_channels cac
    JOIN customer c ON cac.c_customer_sk = c.c_customer_sk
    LEFT JOIN store_agg s ON s.c_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_agg cat ON cat.c_customer_sk = c.c_customer_sk
    LEFT JOIN web_agg w ON w.c_customer_sk = c.c_customer_sk
    LEFT JOIN latest_address la ON la.c_customer_sk = c.c_customer_sk AND la.rn = 1
),
final AS (
    SELECT
        comb.c_customer_sk,
        comb.full_name,
        comb.state,
        comb.store_net_profit,
        comb.catalog_net_profit,
        comb.web_net_profit,
        comb.total_net_profit,
        comb.store_quantity,
        comb.catalog_quantity,
        comb.web_quantity,
        comb.store_transactions,
        comb.catalog_transactions,
        comb.web_transactions,
        comb.store_top_promo,
        comb.catalog_top_promo,
        comb.web_top_promo,
        RANK() OVER (PARTITION BY comb.state ORDER BY comb.total_net_profit DESC) AS state_profit_rank,
        SUM(comb.total_net_profit) OVER (PARTITION BY comb.state ORDER BY comb.total_net_profit ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_state_profit,
        (SELECT MAX(inner_comb.total_net_profit)
         FROM combined inner_comb
         WHERE inner_comb.state = comb.state) AS max_state_profit,
        CASE WHEN comb.total_net_profit > 0 THEN comb.total_net_profit * 1.05 ELSE 0 END AS total_net_profit_with_tax,
        CASE
            WHEN LOWER(comb.store_top_promo) LIKE '%blackfriday%' OR
                 LOWER(comb.catalog_top_promo) LIKE '%blackfriday%' OR
                 LOWER(comb.web_top_promo) LIKE '%blackfriday%' THEN 'YES'
            ELSE 'NO'
        END AS black_friday_promo_flag,
        CASE
            WHEN comb.store_net_profit = 0 AND comb.catalog_net_profit = 0 THEN NULL
            ELSE (comb.store_net_profit + comb.catalog_net_profit) / NULLIF(comb.web_net_profit, 0)
        END AS profit_ratio_store_catalog_to_web
    FROM combined comb
    WHERE EXISTS (
        SELECT 1
        FROM store_sales ss
        JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
        WHERE ss.ss_customer_sk = comb.c_customer_sk
          AND d2.d_year = 2022
          AND ss.ss_quantity > (
              SELECT AVG(ss2.ss_quantity)
              FROM store_sales ss2
              JOIN date_dim d3 ON ss2.ss_sold_date_sk = d3.d_date_sk
              WHERE d3.d_year = 2022
                AND ss2.ss_sold_date_sk = ss.ss_sold_date_sk
          )
    )
)
SELECT *
FROM final
WHERE state_profit_rank <= 10
ORDER BY total_net_profit DESC
LIMIT 100
