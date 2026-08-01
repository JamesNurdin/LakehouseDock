WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
joined_all AS (
    SELECT
        d.d_year,
        i.i_item_id,
        i.i_current_price,
        cp.cp_department,
        w.w_city,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_active_flag,
        (
            SELECT SUM(si.inv_quantity_on_hand)
            FROM sampled_inventory si
            WHERE si.inv_item_sk = i.i_item_sk
        ) AS total_inventory_qty
    FROM
        catalog_page cp
        LEFT OUTER JOIN catalog_returns cr
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT OUTER JOIN warehouse w
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
        LEFT OUTER JOIN item i
            ON cr.cr_item_sk = i.i_item_sk
        LEFT OUTER JOIN date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
        LEFT OUTER JOIN household_demographics hd
            ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        RIGHT OUTER JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT OUTER JOIN promotion p
            ON p.p_item_sk = i.i_item_sk
        LEFT OUTER JOIN web_sales ws
            ON ws.ws_item_sk = i.i_item_sk
        LEFT OUTER JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT OUTER JOIN web_site site
            ON ws.ws_web_site_sk = site.web_site_sk
        LEFT OUTER JOIN store_sales ss
            ON ss.ss_item_sk = i.i_item_sk
        LEFT OUTER JOIN store_returns sr
            ON sr.sr_item_sk = i.i_item_sk
        LEFT OUTER JOIN sampled_inventory inv
            ON inv.inv_item_sk = i.i_item_sk
        LEFT OUTER JOIN date_dim d_ws
            ON ws.ws_sold_date_sk = d_ws.d_date_sk
    WHERE
        d.d_year = 2001
        AND i.i_current_price > 30
        AND w.w_city = 'San Miguel County'
        AND hd.hd_vehicle_count >= 2
        AND ib.ib_lower_bound >= 25000
        AND ws.ws_ext_discount_amt > 0
)
SELECT
    d_year,
    cp_department,
    SUM(sales_amount) AS total_sales,
    SUM(total_inventory_qty) AS total_inventory,
    AVG(i_current_price) AS avg_price,
    SUM(promo_active_flag) AS active_promo_cnt
FROM (
    SELECT
        d_year,
        cp_department,
        ws_ext_sales_price AS sales_amount,
        total_inventory_qty,
        i_current_price,
        promo_active_flag
    FROM joined_all
    WHERE i_current_price < 200
    UNION DISTINCT
    SELECT
        d_year,
        cp_department,
        ws_ext_sales_price * 0.9 AS sales_amount,
        total_inventory_qty,
        i_current_price,
        promo_active_flag
    FROM joined_all
    WHERE i_current_price >= 200
) AS u
GROUP BY d_year, cp_department
HAVING SUM(sales_amount) > 1000
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
