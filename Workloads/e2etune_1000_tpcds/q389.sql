WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_city,
        CAST(ss.ss_sold_date_sk / 1000 AS integer) AS quarter_bucket,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY s.s_store_id, s.s_city, CAST(ss.ss_sold_date_sk / 1000 AS integer)
    HAVING SUM(ss.ss_net_profit) > 0
),
store_top AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY quarter_bucket ORDER BY total_profit DESC) AS profit_rank
    FROM store_agg
),
store_filtered AS (
    SELECT *
    FROM store_top
    WHERE profit_rank <= 5
),
catalog_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        CAST(cp.cp_start_date_sk / 1000 AS integer) AS quarter_bucket,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS num_returns
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'quarterly'
      AND cp.cp_start_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY cp.cp_department, cp.cp_type, CAST(cp.cp_start_date_sk / 1000 AS integer)
    HAVING SUM(cr.cr_return_amount) > 0
),
catalog_top AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY quarter_bucket ORDER BY total_return_amount DESC) AS return_rank
    FROM catalog_agg
),
catalog_filtered AS (
    SELECT *
    FROM catalog_top
    WHERE return_rank <= 5
)
SELECT
    'store' AS source,
    s.s_store_id AS entity_id,
    s.s_city AS entity_name,
    s.quarter_bucket AS quarter,
    s.total_sales,
    s.total_profit,
    s.num_transactions,
    NULL AS total_return_amount,
    NULL AS total_return_qty,
    NULL AS num_returns
FROM store_filtered s
UNION ALL
SELECT
    'catalog' AS source,
    c.cp_department AS entity_id,
    c.cp_type AS entity_name,
    c.quarter_bucket AS quarter,
    NULL AS total_sales,
    NULL AS total_profit,
    NULL AS num_transactions,
    c.total_return_amount,
    c.total_return_qty,
    c.num_returns
FROM catalog_filtered c
ORDER BY source, quarter DESC, total_profit DESC NULLS LAST, total_return_amount DESC NULLS LAST
LIMIT 100
