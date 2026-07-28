WITH base AS (
    SELECT
        ss.ss_ticket_number,
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        c.c_customer_sk,
        c.c_customer_id,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        r.r_reason_desc,
        sm.sm_type,
        cc.cc_state,
        wp.wp_max_ad_count,
        (
            SELECT SUM(inv2.inv_quantity_on_hand)
            FROM inventory inv2
            WHERE inv2.inv_item_sk = cs.cs_item_sk
              AND inv2.inv_date_sk = d.d_date_sk
        ) AS total_inventory_for_item_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
                           AND cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = cs.cs_item_sk
                         AND inv.inv_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND hd.hd_vehicle_count > 2
      AND ib.ib_upper_bound > 50000
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND wp.wp_max_ad_count < 3
)
SELECT
    d_year,
    s_store_name,
    COUNT(DISTINCT ss_ticket_number) AS num_transactions,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(total_inventory_for_item_date) AS avg_inventory_per_item_date,
    COUNT(CASE WHEN r_reason_desc LIKE '%price%' THEN 1 END) AS price_related_returns
FROM base
WHERE EXISTS (
    SELECT 1
    FROM web_page wp2
    WHERE wp2.wp_customer_sk = base.c_customer_sk
      AND wp2.wp_image_count > base.wp_max_ad_count
)
GROUP BY d_year, s_store_name
HAVING SUM(cs_ext_sales_price) > 100000
ORDER BY total_profit DESC
LIMIT 20
