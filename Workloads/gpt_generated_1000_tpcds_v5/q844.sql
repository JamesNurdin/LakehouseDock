WITH store_sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_country,
        s.s_state,
        ca.ca_address_sk,
        ca.ca_state,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_country = 'United States'          -- filter 1
      AND s.s_state = 'CA'                        -- filter 2
      AND ca.ca_state = 'CA'                      -- filter 3
    GROUP BY s.s_store_sk, s.s_store_name, s.s_country, s.s_state, ca.ca_address_sk, ca.ca_state
)
SELECT
    ssa.s_store_name,
    ssa.s_country,
    ssa.s_state,
    ssa.ca_state,
    ssa.total_net_paid,
    ssa.total_net_profit,
    ssa.sales_cnt,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    SUM(cr.cr_net_loss) AS catalog_total_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders,
    SUM(wr.wr_net_loss) AS web_total_net_loss,
    r.r_reason_desc,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty
FROM store_sales_agg ssa
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_addr_sk = ssa.ca_address_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_addr_sk = ssa.ca_address_sk
WHERE r.r_reason_desc = 'Customer Not Satisfied'               -- filter 4
  AND cr.cr_reversed_charge > 100.00                           -- filter 5
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = wr.wr_web_page_sk
          AND wp.wp_char_count > 4000                         -- filter 6
    )
GROUP BY
    ssa.s_store_name,
    ssa.s_country,
    ssa.s_state,
    ssa.ca_state,
    ssa.total_net_paid,
    ssa.total_net_profit,
    ssa.sales_cnt,
    r.r_reason_desc
ORDER BY catalog_total_net_loss DESC
LIMIT 100
