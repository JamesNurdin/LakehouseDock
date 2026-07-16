WITH date_ym AS (
    SELECT
        d_date_sk,
        CONCAT(CAST(d_year AS VARCHAR), '-', LPAD(CAST(d_moy AS VARCHAR), 2, '0')) AS year_month
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 1999
),
store_sales_summary AS (
    SELECT
        ss.ss_item_sk,
        dym.year_month,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        i.i_product_name
    FROM store_sales ss
    LEFT JOIN date_ym dym ON ss.ss_sold_date_sk = dym.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE dym.year_month IS NOT NULL
    GROUP BY ss.ss_item_sk, dym.year_month, i.i_product_name
),
catalog_sales_summary AS (
    SELECT
        cs.cs_item_sk,
        dym.year_month,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_txn_cnt,
        i.i_product_name
    FROM catalog_sales cs
    LEFT JOIN date_ym dym ON cs.cs_sold_date_sk = dym.d_date_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE dym.year_month IS NOT NULL
    GROUP BY cs.cs_item_sk, dym.year_month, i.i_product_name
),
web_sales_summary AS (
    SELECT
        ws.ws_item_sk,
        dym.year_month,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt,
        i.i_product_name
    FROM web_sales ws
    LEFT JOIN date_ym dym ON ws.ws_sold_date_sk = dym.d_date_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE dym.year_month IS NOT NULL
    GROUP BY ws.ws_item_sk, dym.year_month, i.i_product_name
),
combined AS (
    SELECT
        COALESCE(ss.ss_item_sk, cs.cs_item_sk, ws.ws_item_sk) AS item_sk,
        COALESCE(ss.year_month, cs.year_month, ws.year_month) AS year_month,
        ss.store_net_paid,
        ss.store_net_profit,
        ss.store_txn_cnt,
        cs.catalog_net_paid,
        cs.catalog_net_profit,
        cs.catalog_txn_cnt,
        ws.web_net_paid,
        ws.web_net_profit,
        ws.web_txn_cnt,
        COALESCE(ss.i_product_name, cs.i_product_name, ws.i_product_name) AS product_name
    FROM store_sales_summary ss
    FULL OUTER JOIN catalog_sales_summary cs
        ON ss.ss_item_sk = cs.cs_item_sk AND ss.year_month = cs.year_month
    FULL OUTER JOIN web_sales_summary ws
        ON COALESCE(ss.ss_item_sk, cs.cs_item_sk) = ws.ws_item_sk
           AND COALESCE(ss.year_month, cs.year_month) = ws.year_month
),
item_rankings AS (
    SELECT
        item_sk,
        year_month,
        product_name,
        COALESCE(store_net_profit, 0) + COALESCE(catalog_net_profit, 0) + COALESCE(web_net_profit, 0) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY year_month ORDER BY
            (COALESCE(store_net_profit, 0) + COALESCE(catalog_net_profit, 0) + COALESCE(web_net_profit, 0)) DESC) AS profit_rank
    FROM combined
    WHERE COALESCE(store_net_profit, 0) + COALESCE(catalog_net_profit, 0) + COALESCE(web_net_profit, 0) > 0
),
top_items AS (
    SELECT *
    FROM item_rankings
    WHERE profit_rank <= 5
)
SELECT
    ti.year_month,
    ti.product_name,
    ti.total_profit,
    ti.profit_rank,
    CONCAT('Top ', CAST(ti.profit_rank AS VARCHAR), ' Item in ', ti.year_month) AS label,
    (SELECT AVG(COALESCE(ss.store_net_profit,0) + COALESCE(cs.catalog_net_profit,0) + COALESCE(ws.web_net_profit,0))
        FROM combined ss
        LEFT JOIN catalog_sales_summary cs ON ss.item_sk = cs.cs_item_sk AND ss.year_month = cs.year_month
        LEFT JOIN web_sales_summary ws ON ss.item_sk = ws.ws_item_sk AND ss.year_month = ws.year_month
        WHERE ss.year_month = ti.year_month) AS avg_monthly_profit,
    CASE
        WHEN ti.total_profit > (SELECT AVG(total_profit) FROM item_rankings WHERE year_month = ti.year_month) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM top_items ti

UNION ALL

SELECT
    mr.year_month,
    CAST(NULL AS VARCHAR) AS product_name,
    mr.month_total_profit AS total_profit,
    CAST(NULL AS INTEGER) AS profit_rank,
    CONCAT('Month Total ', mr.year_month) AS label,
    CAST(NULL AS DOUBLE) AS avg_monthly_profit,
    'Summary' AS profit_category
FROM (
    SELECT
        year_month,
        SUM(total_profit) AS month_total_profit
    FROM item_rankings
    GROUP BY year_month
) mr
ORDER BY year_month, profit_rank
