WITH sr_agg AS (
    SELECT
        sr_store_sk,
        sr_returned_date_sk,
        SUM(sr_net_loss) AS total_store_net_loss,
        COUNT(*) AS cnt_returns
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_store_sk, sr_returned_date_sk
)
SELECT DISTINCT
    d.d_year,
    s.s_store_name,
    sm.sm_carrier,
    r.r_reason_desc,
    sr_agg.total_store_net_loss,
    cr.cr_return_amount,
    ws.ws_net_profit,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY sr_agg.total_store_net_loss DESC) AS store_loss_rank,
    CASE
        WHEN cr.cr_return_amount > (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_return_amount IS NOT NULL
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_amount_category
FROM sr_agg
JOIN store s
    ON sr_agg.sr_store_sk = s.s_store_sk
JOIN date_dim d
    ON sr_agg.sr_returned_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
    AND wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wr.wr_reason_sk = r.r_reason_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d.d_year = 2000
  AND sm.sm_carrier IN ('UPS', 'DHL')
  AND cr.cr_return_amount > 0
  AND wp.wp_max_ad_count > 2
  AND inv.inv_quantity_on_hand >= 0
ORDER BY sr_agg.total_store_net_loss DESC, store_loss_rank
LIMIT 100
