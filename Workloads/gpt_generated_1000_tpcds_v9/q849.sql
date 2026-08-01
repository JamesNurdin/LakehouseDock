WITH
    high_profit_stores AS (
        SELECT ss.ss_store_sk
        FROM store_sales ss
        GROUP BY ss.ss_store_sk
        HAVING SUM(ss.ss_net_profit) > 10000
    ),
    high_loss_stores AS (
        SELECT sr.sr_store_sk AS ss_store_sk
        FROM store_returns sr
        GROUP BY sr.sr_store_sk
        HAVING SUM(sr.sr_net_loss) > 5000
    ),
    intersected_stores AS (
        SELECT ss_store_sk FROM high_profit_stores
        INTERSECT
        SELECT ss_store_sk FROM high_loss_stores
    )
SELECT
    agg.s_store_name,
    agg.i_category,
    agg.d_year,
    agg.total_net_profit,
    agg.total_return_loss,
    agg.distinct_items_sold,
    CASE WHEN agg.total_net_profit > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY agg.s_store_name ORDER BY agg.total_net_profit DESC) AS profit_rank,
    agg.avg_store_net_profit,
    agg.call_center_name
FROM (
    SELECT
        s.s_store_name,
        i.i_category,
        d.d_year,
        SUM(ss.ss_net_profit)                               AS total_net_profit,
        SUM(COALESCE(sr.sr_net_loss, 0))                   AS total_return_loss,
        COUNT(DISTINCT i.i_item_sk)                        AS distinct_items_sold,
        COALESCE(cc.cc_name, 'No Call Center')            AS call_center_name,
        /* Correlated subquery – average profit for the store across all its sales */
        (SELECT AVG(ss2.ss_net_profit)
         FROM store_sales ss2
         WHERE ss2.ss_store_sk = s.s_store_sk)          AS avg_store_net_profit,
        s.s_store_sk                                        -- needed for the correlation above
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                                   AND cr.cr_item_sk = i.i_item_sk
        LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
        LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                                   AND sr.sr_item_sk = i.i_item_sk
                                   AND sr.sr_store_sk = s.s_store_sk
                                   AND sr.sr_ticket_number = ss.ss_ticket_number
        LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                               AND ws.ws_item_sk = i.i_item_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                                 AND wr.wr_item_sk = i.i_item_sk
                                 AND wr.wr_web_page_sk = wp.wp_web_page_sk
                                 AND wr.wr_order_number = ws.ws_order_number
        LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = d.d_date_sk
          AND cr2.cr_item_sk = i.i_item_sk
    )
    AND ss.ss_store_sk IN (SELECT ss_store_sk FROM intersected_stores)
    GROUP BY
        CUBE (s.s_store_name, i.i_category, d.d_year),
        cc.cc_name,
        s.s_store_sk
    HAVING SUM(ss.ss_net_profit) > 0
) agg
ORDER BY agg.total_net_profit DESC
LIMIT 100
