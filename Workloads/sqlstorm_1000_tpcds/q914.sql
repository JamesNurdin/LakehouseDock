WITH store_sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        s.s_state AS state,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_txn,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
    GROUP BY s.s_store_id, d.d_year, s.s_state
),
store_returns_agg AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_txn
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, d.d_year
),
store_combined AS (
    SELECT
        ss.store_id,
        ss.year,
        ss.state,
        ss.total_net_paid,
        COALESCE(sr.total_net_loss, 0) AS total_net_loss,
        ss.sales_txn,
        COALESCE(sr.return_txn, 0) AS return_txn,
        CASE WHEN ss.total_net_paid - COALESCE(sr.total_net_loss, 0) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS overall_status,
        ROW_NUMBER() OVER (PARTITION BY ss.state ORDER BY ss.total_net_profit DESC) AS profit_rank_state
    FROM store_sales_agg ss
    LEFT JOIN store_returns_agg sr
        ON ss.store_id = sr.store_id AND ss.year = sr.year
),
catalog_sales_agg AS (
    SELECT
        cp.cp_catalog_page_id AS catalog_page_id,
        d.d_year AS year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_txn,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cp.cp_catalog_page_id, d.d_year
),
catalog_returns_agg AS (
    SELECT
        cp.cp_catalog_page_id AS catalog_page_id,
        d.d_year AS year,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_txn
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cp.cp_catalog_page_id, d.d_year
),
catalog_combined AS (
    SELECT
        cs.catalog_page_id,
        cs.year,
        cs.total_net_paid,
        COALESCE(cr.total_net_loss, 0) AS total_net_loss,
        cs.sales_txn,
        COALESCE(cr.return_txn, 0) AS return_txn,
        CASE WHEN cs.total_net_paid - COALESCE(cr.total_net_loss, 0) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS overall_status,
        RANK() OVER (PARTITION BY cs.year ORDER BY cs.total_net_profit DESC) AS profit_rank_year
    FROM catalog_sales_agg cs
    LEFT JOIN catalog_returns_agg cr
        ON cs.catalog_page_id = cr.catalog_page_id AND cs.year = cr.year
),
final_union AS (
    SELECT
        'store' AS channel,
        sc.store_id AS id,
        sc.year,
        sc.state,
        sc.total_net_paid,
        sc.total_net_loss,
        sc.sales_txn,
        sc.return_txn,
        sc.overall_status,
        sc.profit_rank_state AS rank_in_state
    FROM store_combined sc
    WHERE sc.sales_txn > 100
    UNION ALL
    SELECT
        'catalog' AS channel,
        cc.catalog_page_id AS id,
        cc.year,
        NULL AS state,
        cc.total_net_paid,
        cc.total_net_loss,
        cc.sales_txn,
        cc.return_txn,
        cc.overall_status,
        cc.profit_rank_year AS rank_in_state
    FROM catalog_combined cc
    WHERE cc.sales_txn > 100
)
SELECT
    fu.channel,
    fu.id,
    fu.year,
    COALESCE(fu.state, 'N/A') AS state,
    fu.total_net_paid,
    fu.total_net_loss,
    (fu.total_net_paid - fu.total_net_loss) AS net_contribution,
    fu.sales_txn,
    fu.return_txn,
    fu.overall_status,
    fu.rank_in_state,
    CASE
        WHEN fu.overall_status = 'PROFIT' AND fu.rank_in_state = 1 THEN 'TOP'
        WHEN fu.overall_status = 'PROFIT' THEN 'GOOD'
        ELSE 'BAD'
    END AS performance_tier,
    CONCAT(fu.id, '-', CAST(fu.year AS VARCHAR), '-', fu.channel) AS composite_key,
    CASE WHEN EXISTS (
        SELECT 1 FROM final_union fu2
        WHERE fu2.year = fu.year
          AND fu2.channel <> fu.channel
          AND (fu2.total_net_paid - fu2.total_net_loss) > (fu.total_net_paid - fu.total_net_loss)
    ) THEN 'COMPETED' ELSE 'UNIQUE' END AS competition_flag
FROM final_union fu
WHERE (fu.total_net_paid - fu.total_net_loss) > (
    SELECT AVG(total_net_paid - total_net_loss) FROM final_union
)
ORDER BY net_contribution DESC
LIMIT 100
