WITH joined_data AS (
    SELECT
        d.d_year,
        cp.cp_department,
        cc.cc_name,
        w.w_warehouse_name,
        ca.ca_state,
        cust.c_customer_sk,
        cust.c_preferred_cust_flag,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_net_loss,
        inv.inv_quantity_on_hand,
        wp.wp_char_count,
        wp.wp_max_ad_count,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer cust
      ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    LEFT JOIN promotion p
      ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    LEFT JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
         AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr
      ON sr.sr_customer_sk = cust.c_customer_sk
         AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
      ON wp.wp_customer_sk = cust.c_customer_sk
         AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND ca.ca_state = 'CA'
      AND cust.c_preferred_cust_flag = 'Y'
)
SELECT
    jd.d_year,
    jd.cp_department,
    jd.cc_name,
    jd.w_warehouse_name,
    SUM(jd.cr_return_amount) AS total_return_amount,
    SUM(jd.cr_return_tax) AS total_tax,
    SUM(jd.cr_return_quantity) AS total_return_qty,
    COUNT(DISTINCT jd.cr_item_sk) AS distinct_items,
    MAX(jd.inv_quantity_on_hand) AS max_inventory_on_hand,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM web_page wp2
            WHERE wp2.wp_customer_sk = jd.c_customer_sk
              AND wp2.wp_char_count > 2500
        ) THEN 'High'
        ELSE 'Low'
    END AS page_activity_level,
    DENSE_RANK() OVER (PARTITION BY jd.d_year ORDER BY SUM(jd.cr_return_amount) DESC) AS revenue_rank
FROM joined_data jd
GROUP BY
    jd.d_year,
    jd.cp_department,
    jd.cc_name,
    jd.w_warehouse_name,
    jd.c_customer_sk
HAVING SUM(jd.cr_return_amount) > 5000
ORDER BY jd.d_year, revenue_rank
LIMIT 100
