WITH ss_daily AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS daily_sales,
        COUNT(*) AS daily_txn
    FROM store_sales ss
    JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    WHERE td_ss.t_sub_shift = 'morning'
      AND p_ss.p_discount_active = 'Y'
    GROUP BY ss.ss_sold_date_sk
)
SELECT
    cr.cr_returned_date_sk AS return_date_sk,
    c.c_customer_id,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    CASE WHEN SUM(cr.cr_return_quantity) > 10 THEN 'HIGH' ELSE 'LOW' END AS return_volume_category,
    (SELECT COUNT(*) FROM inventory inv_sub WHERE inv_sub.inv_warehouse_sk = w.w_warehouse_sk) AS inventory_cnt,
    ss_agg.daily_sales,
    ss_agg.daily_txn
FROM catalog_returns cr
JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
JOIN store_returns sr
    ON sr.sr_return_time_sk = td.t_time_sk
JOIN store_sales ss
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
   AND ss.ss_sold_time_sk = td.t_time_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ss_daily ss_agg
    ON ss_agg.sold_date_sk = ss.ss_sold_date_sk
WHERE c.c_birth_country = 'United States'
  AND ib.ib_lower_bound >= 50000
  AND td.t_sub_shift = 'morning'
GROUP BY
    cr.cr_returned_date_sk,
    c.c_customer_id,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    w.w_warehouse_sk,
    ss_agg.daily_sales,
    ss_agg.daily_txn
ORDER BY total_net_loss DESC
LIMIT 100
