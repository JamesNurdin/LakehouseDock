/*
Goal: Identify stores and catalog pages whose net loss exceeds the overall average net loss for high‑income customers. The analysis filters by business hours, item unit type, state, and income band, and excludes any stores that have returns flagged as 'Damaged'. The query joins all 12 selected tables using only the allowed join keys, aggregates data in multiple CTEs, uses a UNION ALL set operation, includes a LEFT OUTER JOIN, applies an anti‑join via NOT EXISTS, leverages a window function for ranking, and returns the top results ordered by net loss.
*/
WITH
store_sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_state,
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_units = 'Case'
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound >= 50000
    GROUP BY s.s_store_sk, s.s_store_id, s.s_state, hd.hd_demo_sk, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
store_returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_state,
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    WHERE t.t_hour BETWEEN 9 AND 21
      AND i.i_units = 'Case'
      AND s.s_state = 'CA'
      AND ib.ib_upper_bound <= 150000
    GROUP BY s.s_store_sk, s.s_store_id, s.s_state, hd.hd_demo_sk, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
catalog_returns_agg AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_units = 'Case'
      AND cp.cp_department = 'Electronics'
      AND ib.ib_lower_bound >= 75000
      AND t.t_hour BETWEEN 0 AND 23
    GROUP BY cp.cp_catalog_page_sk, cp.cp_catalog_page_id, cp.cp_department, hd.hd_demo_sk, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
combined AS (
    SELECT
        'store' AS entity_type,
        s.s_store_sk AS entity_key,
        s.s_store_id AS entity_id,
        s.s_state,
        s.total_net_loss
    FROM store_returns_agg s
    UNION ALL
    SELECT
        'catalog_page' AS entity_type,
        cp.cp_catalog_page_sk AS entity_key,
        cp.cp_catalog_page_id AS entity_id,
        NULL AS s_state,
        cp.total_net_loss
    FROM catalog_returns_agg cp
),
average_loss AS (
    SELECT AVG(total_net_loss) AS avg_loss FROM combined
),
ranked AS (
    SELECT
        c.entity_type,
        c.entity_key,
        c.entity_id,
        c.s_state,
        c.total_net_loss,
        al.avg_loss,
        CASE WHEN c.total_net_loss > al.avg_loss THEN 1 ELSE 0 END AS above_average,
        ROW_NUMBER() OVER (PARTITION BY c.entity_type ORDER BY c.total_net_loss DESC) AS rn
    FROM combined c
    CROSS JOIN average_loss al
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_store_sk = c.entity_key
          AND c.entity_type = 'store'
          AND r2.r_reason_desc = 'Damaged'
    )
)
SELECT
    entity_type,
    entity_id,
    s_state,
    total_net_loss,
    avg_loss,
    (SELECT MAX(total_net_loss) FROM combined) AS max_loss_overall,
    above_average,
    rn
FROM ranked
WHERE above_average = 1
ORDER BY total_net_loss DESC
LIMIT 100
