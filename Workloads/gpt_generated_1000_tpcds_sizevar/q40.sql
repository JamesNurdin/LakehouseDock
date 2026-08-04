WITH item_sales AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        cd.cd_gender,
        cd.cd_education_status,
        inv.inv_quantity_on_hand,
        cp.cp_description,
        sm.sm_carrier,
        wp.wp_type,
        SUM(ss.ss_quantity) AS total_qty_sold,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_sales_price) AS total_sales_price,
        SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(wr.wr_return_quantity) AS total_web_return_qty,
        SUM(wr.wr_return_amt) AS total_web_return_amt
    FROM item i
    RIGHT OUTER JOIN store_sales ss
        ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_returns cr
        ON i.i_item_sk = cr.cr_item_sk
    LEFT JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
    LEFT JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_current_price > 20
      AND ss.ss_sold_date_sk BETWEEN 2451000 AND 2451100
      AND cp.cp_end_date_sk > 2451000
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        cd.cd_gender,
        cd.cd_education_status,
        inv.inv_quantity_on_hand,
        cp.cp_description,
        sm.sm_carrier,
        wp.wp_type
)
SELECT
    i_item_id,
    i_product_name,
    i_brand,
    i_category,
    i_current_price,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    cd_gender,
    cd_education_status,
    inv_quantity_on_hand,
    total_qty_sold,
    total_net_paid,
    total_sales_price,
    total_catalog_return_qty,
    total_catalog_return_amount,
    total_web_return_qty,
    total_web_return_amt,
    cp_description,
    sm_carrier,
    wp_type,
    RANK() OVER (ORDER BY total_net_paid DESC) AS sales_rank,
    CASE 
        WHEN total_catalog_return_qty > 0 THEN 'Catalog Return'
        WHEN total_web_return_qty > 0 THEN 'Web Return'
        ELSE 'No Return'
    END AS return_flag
FROM item_sales
ORDER BY sales_rank
LIMIT 100
