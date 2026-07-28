-- Goal: Analyze the financial impact of a specific return reason across catalog, store and web channels,
-- joining all seven tables, applying realistic filters, using a scalar subquery, and aggregating key metrics.
WITH filtered_cr AS (
    SELECT cr.*
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
    )
)
, joined AS (
    SELECT
        r.r_reason_desc,
        cr.cr_return_amount,
        cr.cr_net_loss               AS cr_net_loss,
        sr.sr_return_amt             AS sr_return_amt,
        sr.sr_net_loss               AS sr_net_loss,
        ws.ws_net_profit             AS ws_net_profit,
        wp.wp_image_count            AS wp_image_count,
        wp.wp_rec_end_date           AS wp_rec_end_date
    FROM filtered_cr cr
    JOIN customer_address ca_ref      ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN reason r                     ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr             ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_store    ON sr.sr_addr_sk = ca_store.ca_address_sk
    JOIN web_sales ws                 ON ws.ws_bill_addr_sk = ca_store.ca_address_sk
    JOIN web_page wp                  ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr               ON wr.wr_order_number = ws.ws_order_number
    WHERE r.r_reason_desc = 'Did not like the color'
      AND wp.wp_image_count > 4
      AND wp.wp_rec_end_date = DATE '2000-09-02'
)
SELECT
    r_reason_desc,
    COUNT(*)                                     AS total_transactions,
    SUM(cr_return_amount)                        AS total_catalog_return_amount,
    SUM(cr_net_loss + sr_net_loss)               AS total_net_loss,
    AVG(ws_net_profit)                           AS avg_web_profit,
    MIN(wp_image_count)                         AS min_image_count,
    MAX(wp_image_count)                         AS max_image_count
FROM joined
GROUP BY r_reason_desc
ORDER BY total_transactions DESC
LIMIT 100
