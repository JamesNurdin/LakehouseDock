/*
  Goal: Summarize profitability and return‑loss metrics per store and catalog department, 
        limited to stores in CA‑Spring with specific street types, household demographics, 
        income bands and high‑value web returns. The query joins all nine selected tables, 
        uses a LEFT OUTER join, applies many filters, aggregates several measures, 
        includes a correlated scalar sub‑query, orders the result and caps it at 100 rows.
*/
WITH sales_base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        s.s_store_id,
        s.s_state,
        s.s_city,
        s.s_street_type,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        cp.cp_department,
        cp.cp_catalog_page_sk,
        cr.cr_net_loss,
        cr.cr_return_amount,
        sr.sr_net_loss        AS sr_net_loss,
        wr.wr_net_loss        AS wr_net_loss,
        wr.wr_return_amt,
        wp.wp_type
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    /* left‑outer join to capture stores that may have no returns */
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    /* catalog page is filtered first; then catalog returns are left‑joined */
    LEFT JOIN catalog_page cp
        ON cp.cp_department = 'Electronics'
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE s.s_state = 'CA'
      AND s.s_city = 'Spring'
      AND s.s_street_type IN ('Court', 'ST')
      AND hd.hd_dep_count >= 2
      AND hd.hd_vehicle_count >= 0
      AND ib.ib_lower_bound >= 30000
      AND EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_return_amt > 100
            AND wr2.wr_web_page_sk = wp.wp_web_page_sk
      )
)
SELECT
    s_store_id,
    s_state,
    s_city,
    cp_department,
    ib_lower_bound,
    COUNT(DISTINCT ss_ticket_number)                     AS sales_txn_cnt,
    SUM(ss_net_profit)                                 AS total_net_profit,
    SUM(COALESCE(sr_net_loss, 0))                      AS total_store_return_loss,
    SUM(COALESCE(cr_net_loss, 0))                      AS total_catalog_return_loss,
    SUM(COALESCE(wr_net_loss, 0))                      AS total_web_return_loss,
    AVG(ss_quantity)                                   AS avg_quantity,
    (
        SELECT MAX(cr3.cr_return_amount)
        FROM catalog_returns cr3
        JOIN catalog_page cp3 ON cr3.cr_catalog_page_sk = cp3.cp_catalog_page_sk
        WHERE cp3.cp_department = sales_base.cp_department
    )                                                  AS max_catalog_return_amount
FROM sales_base
GROUP BY
    s_store_id,
    s_state,
    s_city,
    cp_department,
    ib_lower_bound
HAVING SUM(ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
