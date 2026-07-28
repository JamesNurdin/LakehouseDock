WITH joined_data AS (
    SELECT
        cr.cr_return_amount               AS catalog_return_amount,
        sr.sr_return_amt                  AS store_return_amount,
        wr.wr_return_amt                  AS web_return_amount,
        inv.inv_quantity_on_hand          AS inventory_qty,
        p.p_cost                           AS promo_cost,
        i.i_item_id,
        i.i_item_sk,
        i.i_category,
        d.d_year,
        cp.cp_department,
        cd.cd_gender,
        hd.hd_vehicle_count,
        sm.sm_type,
        wp.wp_url,
        ca.ca_city
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c_refunded
      ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
     AND sr.sr_item_sk = i.i_item_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_item_sk = i.i_item_sk
     AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
     AND inv.inv_item_sk = i.i_item_sk
    JOIN promotion p
      ON p.p_start_date_sk = d.d_date_sk
     AND p.p_item_sk = i.i_item_sk
    JOIN customer c_wp
      ON wp.wp_customer_sk = c_wp.c_customer_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#45'
      AND cd.cd_gender = 'M'
      AND hd.hd_vehicle_count >= 2
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
      AND cp.cp_department = 'Electronics'
),
aggregated AS (
    SELECT
        i_item_id,
        i_item_sk,
        d_year,
        cp_department,
        SUM(catalog_return_amount)           AS total_catalog_return,
        SUM(store_return_amount)             AS total_store_return,
        SUM(web_return_amount)               AS total_web_return,
        SUM(inventory_qty)                   AS total_inventory_qty,
        SUM(promo_cost)                      AS total_promo_cost,
        SUM(catalog_return_amount + store_return_amount + web_return_amount) AS total_return_amount
    FROM joined_data
    GROUP BY i_item_id, i_item_sk, d_year, cp_department
)
SELECT
    a.i_item_id,
    a.d_year,
    a.cp_department,
    a.total_return_amount,
    a.total_inventory_qty,
    a.total_promo_cost,
    SUM(a.total_return_amount) OVER (PARTITION BY a.cp_department) AS dept_total_return,
    RANK() OVER (ORDER BY a.total_return_amount DESC)                     AS return_rank,
    (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_item_sk = a.i_item_sk
    ) AS max_promo_cost
FROM aggregated a
ORDER BY a.total_return_amount DESC
LIMIT 100
