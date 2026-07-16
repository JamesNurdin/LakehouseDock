SELECT
    d.d_date AS return_date,
    s.s_store_name,
    hd_refunded.hd_buy_potential AS refunded_buy_potential,
    hd_returning.hd_buy_potential AS returning_buy_potential,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    AVG(hd_refunded.hd_income_band_sk) AS avg_refunded_income_band,
    AVG(hd_returning.hd_income_band_sk) AS avg_returning_income_band,
    MAX(wp.wp_max_ad_count) AS max_ad_count,
    MIN(wp.wp_image_count) AS min_image_count
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
   AND wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY
    d.d_date,
    s.s_store_name,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_buy_potential
ORDER BY total_net_loss DESC
LIMIT 100
