WITH store_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_txn_cnt,
        AVG(ss.ss_net_paid) AS avg_store_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_product_name, '^.*[A-Z]{2}.*$')
      AND c.c_last_name LIKE 'S%'
    GROUP BY i.i_item_sk, i.i_product_name
)
SELECT
    sa.i_item_sk,
    sa.i_product_name,
    sa.store_net_paid,
    sa.store_net_profit,
    CASE
        WHEN sa.store_net_profit / NULLIF(sa.store_net_paid, 0) > 0.20 THEN 'HIGH'
        WHEN sa.store_net_profit / NULLIF(sa.store_net_paid, 0) > 0.10 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    substring(sa.i_product_name, 1, 3) AS product_prefix,
    (
        SELECT AVG(ws.ws_net_profit)
        FROM web_sales ws
        JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ) AS avg_web_profit,
    EXISTS (
        SELECT 1
        FROM catalog_page cp
        JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN date_dim d3 ON cp.cp_start_date_sk = d3.d_date_sk
        WHERE d3.d_year = 2001
          AND regexp_like(cp.cp_description, CONCAT('.*', substring(sa.i_product_name, 1, 3), '.*'))
          AND cs.cs_item_sk = sa.i_item_sk
    ) AS has_catalog_match
FROM store_agg sa
ORDER BY sa.store_net_paid DESC
LIMIT 100
