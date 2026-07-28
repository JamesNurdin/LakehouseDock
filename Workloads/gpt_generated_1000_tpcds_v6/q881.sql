WITH subquery_a AS (
    SELECT
        d.d_year AS year,
        w.w_warehouse_name AS warehouse,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        AVG(i.i_current_price) AS avg_item_price,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(wr.wr_return_amt) AS total_web_returns,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        MAX(cc.cc_gmt_offset) AS max_cc_offset
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE w.w_street_name IN ('Ash Laurel', 'Elm Madison')
      AND ca.ca_gmt_offset = -5.00
      AND i.i_color = 'Red'
      AND p.p_discount_active = 'Y'
      AND d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND EXISTS (
          SELECT 1 FROM web_returns wr2
          WHERE wr2.wr_item_sk = i.i_item_sk
            AND wr2.wr_returned_date_sk = d.d_date_sk
            AND wr2.wr_return_quantity > 0
      )
    GROUP BY d.d_year, w.w_warehouse_name
),
subquery_b AS (
    SELECT
        d.d_year AS year,
        w.w_warehouse_name AS warehouse,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        AVG(i.i_current_price) AS avg_item_price,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(wr.wr_return_amt) AS total_web_returns,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        MAX(cc.cc_gmt_offset) AS max_cc_offset
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE w.w_street_type = 'Ct.'
      AND ca.ca_gmt_offset = -7.00
      AND i.i_size = 'M'
      AND p.p_channel_tv = 'Y'
      AND d.d_year = 2002
      AND sm.sm_type = 'GROUND'
      AND EXISTS (
          SELECT 1 FROM web_returns wr2
          WHERE wr2.wr_item_sk = i.i_item_sk
            AND wr2.wr_returned_date_sk = d.d_date_sk
            AND wr2.wr_return_quantity > 0
      )
    GROUP BY d.d_year, w.w_warehouse_name
)
SELECT * FROM (
    SELECT * FROM subquery_a
    UNION ALL
    SELECT * FROM subquery_b
) combined
ORDER BY year DESC, total_sales DESC
LIMIT 100
