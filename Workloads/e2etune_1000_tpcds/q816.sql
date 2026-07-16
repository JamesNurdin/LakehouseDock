SELECT
    d_ret.d_year,
    d_ret.d_month_seq AS month_seq,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers,
    COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_refunded_customers,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT p_start.p_promo_id) AS promotions_started,
    SUM(wp.wp_image_count) AS total_images_created
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN income_band ib
    ON hd_ret.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d_ret.d_date_sk
LEFT JOIN promotion p_start
    ON p_start.p_start_date_sk = d_ret.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year >= 2000
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 50
