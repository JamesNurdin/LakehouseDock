WITH agg_store_returns AS (
    SELECT sr_store_sk,
           SUM(sr_net_loss) AS total_store_net_loss,
           COUNT(*) AS cnt_store_returns
    FROM store_returns
    GROUP BY sr_store_sk
),
promo_item AS (
    SELECT p.p_promo_sk,
           i.i_item_sk,
           p.p_channel_demo,
           p.p_channel_radio,
           p.p_discount_active
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
)
SELECT
    s.s_store_name,
    cp.cp_department,
    pi.p_channel_demo,
    d_cr.d_year,
    SUM(COALESCE(agg.total_store_net_loss, 0)) AS store_net_loss,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
FROM store s
RIGHT OUTER JOIN agg_store_returns agg
    ON s.s_store_sk = agg.sr_store_sk
LEFT JOIN store_returns sr
    ON s.s_store_sk = sr.sr_store_sk
LEFT JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN catalog_returns cr
    ON d_sr.d_date_sk = cr.cr_returned_date_sk
LEFT JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_returns wr
    ON d_sr.d_date_sk = wr.wr_returned_date_sk
LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN item i_sr
    ON sr.sr_item_sk = i_sr.i_item_sk
LEFT JOIN item i_cr
    ON cr.cr_item_sk = i_cr.i_item_sk
LEFT JOIN item i_wr
    ON wr.wr_item_sk = i_wr.i_item_sk
LEFT JOIN customer cust_refund
    ON cr.cr_refunded_customer_sk = cust_refund.c_customer_sk
LEFT JOIN customer cust_return
    ON cr.cr_returning_customer_sk = cust_return.c_customer_sk
LEFT JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
LEFT JOIN income_band ib
    ON hd_sr.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN promo_item pi
    ON i_cr.i_item_sk = pi.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_item_sk = i_cr.i_item_sk
      AND p2.p_channel_demo = 'Y'
)
GROUP BY ROLLUP (s.s_store_name, cp.cp_department, pi.p_channel_demo, d_cr.d_year)
ORDER BY store_net_loss DESC
LIMIT 100
