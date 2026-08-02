WITH
union_items AS (
    SELECT i.i_category AS cat_category
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    UNION
    SELECT i.i_category AS cat_category
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
),
joined_data AS (
    SELECT
        i.i_category,
        i.i_class,
        i.i_brand,
        cd.cd_gender AS cd_gender,
        dd_sales.d_year AS d_year,
        cc.cc_state,
        ib.ib_upper_bound,
        ws.ws_net_paid,
        ws.ws_order_number,
        sr.sr_net_loss,
        cr.cr_net_loss,
        inv.inv_quantity_on_hand,
        r.r_reason_desc,
        w.w_warehouse_name,
        wp.wp_type,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ws.ws_net_paid DESC) AS rn,
        RANK() OVER (PARTITION BY i.i_category ORDER BY ws.ws_net_paid DESC) AS rk
    FROM
        web_sales ws
        JOIN date_dim dd_sales ON ws.ws_sold_date_sk = dd_sales.d_date_sk
        JOIN date_dim dd_ship ON ws.ws_ship_date_sk = dd_ship.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN store_returns sr
            ON sr.sr_item_sk = i.i_item_sk
            AND sr.sr_returned_date_sk = dd_sales.d_date_sk
            AND sr.sr_cdemo_sk = cd.cd_demo_sk
            AND sr.sr_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_item_sk = i.i_item_sk
            AND cr.cr_returned_date_sk = dd_sales.d_date_sk
            AND cr.cr_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = dd_sales.d_date_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN reason r
            ON (sr.sr_reason_sk = r.r_reason_sk OR cr.cr_reason_sk = r.r_reason_sk)
        LEFT JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN date_dim dd_cc_open ON cc.cc_open_date_sk = dd_cc_open.d_date_sk
        LEFT JOIN date_dim dd_cc_closed ON cc.cc_closed_date_sk = dd_cc_closed.d_date_sk
        LEFT JOIN date_dim dd_wp_creation ON wp.wp_creation_date_sk = dd_wp_creation.d_date_sk
        LEFT JOIN date_dim dd_wp_access ON wp.wp_access_date_sk = dd_wp_access.d_date_sk
    WHERE
        dd_sales.d_year = 2001
        AND i.i_brand = 'Brand#23'
        AND cc.cc_state = 'CA'
        AND ib.ib_upper_bound > 80000
        AND r.r_reason_desc LIKE '%damaged%'
        AND w.w_state = 'CA'
        AND wp.wp_type = 'home'
        AND cc.cc_tax_percentage > (
            SELECT AVG(cc2.cc_tax_percentage) FROM call_center cc2
        )
)
SELECT
    jd.i_category,
    jd.cd_gender,
    jd.d_year,
    jd.cc_state,
    jd.ib_upper_bound,
    SUM(jd.ws_net_paid) AS total_net_paid,
    SUM(jd.sr_net_loss) AS total_sr_net_loss,
    SUM(jd.cr_net_loss) AS total_cr_net_loss,
    SUM(jd.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT jd.ws_order_number) AS distinct_orders,
    MAX(jd.rn) AS max_row_num,
    MAX(jd.rk) AS max_rank
FROM joined_data jd
JOIN union_items ui ON ui.cat_category = jd.i_category
GROUP BY CUBE(jd.i_category, jd.cd_gender, jd.d_year, jd.cc_state, jd.ib_upper_bound)
HAVING SUM(jd.ws_net_paid) > (
    SELECT SUM(ws3.ws_net_paid)
    FROM web_sales ws3
    WHERE ws3.ws_sold_date_sk = (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2000 LIMIT 1
    )
)
ORDER BY total_net_paid DESC
LIMIT 100
