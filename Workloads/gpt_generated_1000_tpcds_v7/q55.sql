WITH cr_agg AS (
    SELECT
        cr_item_sk,
        cr_returned_date_sk,
        SUM(cr_return_quantity) AS total_quantity,
        SUM(cr_net_loss) AS total_net_loss
    FROM catalog_returns
    GROUP BY cr_item_sk, cr_returned_date_sk
)
SELECT
    i.i_category,
    d_ret.d_year,
    ws.web_name,
    SUM(agg.total_quantity) AS total_return_qty,
    SUM(agg.total_net_loss) AS total_net_loss,
    COUNT(DISTINCT cd_refunded.cd_demo_sk) AS refunded_customer_count,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(wr.wr_return_quantity) AS web_return_qty,
    (SELECT MIN(ib_lower_bound) FROM income_band) AS min_income_lower_bound
FROM cr_agg agg
JOIN catalog_returns cr
    ON agg.cr_item_sk = cr.cr_item_sk
   AND agg.cr_returned_date_sk = cr.cr_returned_date_sk
JOIN item i
    ON agg.cr_item_sk = i.i_item_sk
JOIN date_dim d_ret
    ON agg.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN income_band ib
    ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_returns wr
    ON agg.cr_item_sk = wr.wr_item_sk
   AND agg.cr_returned_date_sk = wr.wr_returned_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim wp_creation
    ON wp.wp_creation_date_sk = wp_creation.d_date_sk
JOIN date_dim wp_access
    ON wp.wp_access_date_sk = wp_access.d_date_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN date_dim p_start
    ON p.p_start_date_sk = p_start.d_date_sk
JOIN date_dim p_end
    ON p.p_end_date_sk = p_end.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
WHERE agg.cr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_cost > 0
    )
GROUP BY i.i_category, d_ret.d_year, ws.web_name
HAVING SUM(agg.total_net_loss) > 1000
ORDER BY total_net_loss DESC, i.i_category
LIMIT 100
