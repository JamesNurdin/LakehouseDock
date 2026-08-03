WITH all_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        sm.sm_code,
        cc.cc_state,
        cp.cp_department,
        inv.inv_quantity_on_hand,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        sr.sr_return_quantity,
        wp.wp_url,
        -- Lateral sub‑query that calculates total sales for the catalog page of the current row
        pg.page_total_sales
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd2
      ON hd.hd_demo_sk = hd2.hd_demo_sk
    JOIN income_band ib
      ON hd2.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT SUM(cs2.cs_ext_sales_price) AS page_total_sales
        FROM catalog_sales cs2
        WHERE cs2.cs_catalog_page_sk = cs.cs_catalog_page_sk
    ) AS pg
    WHERE cs.cs_ext_sales_price > 1000
      AND sm.sm_code = 'AIR'
      AND cc.cc_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND ib.ib_upper_bound < 150000
      AND inv.inv_quantity_on_hand > 0
),
high_sales AS (
    SELECT cs_order_number FROM all_data WHERE cs_ext_sales_price > 2000
),
air_ship AS (
    SELECT cs_order_number FROM all_data WHERE sm_code = 'AIR'
),
large_inventory AS (
    SELECT cs_order_number FROM all_data WHERE inv_quantity_on_hand > 200
),
low_income AS (
    SELECT cs_order_number FROM all_data WHERE ib_upper_bound < 120000
),
combined AS (
    SELECT cs_order_number FROM high_sales
    UNION
    SELECT cs_order_number FROM air_ship
)
SELECT
    cs_order_number,
    ROW_NUMBER() OVER (ORDER BY cs_order_number) AS global_row_num
FROM (
    SELECT cs_order_number FROM combined
    EXCEPT
    (SELECT cs_order_number FROM large_inventory INTERSECT SELECT cs_order_number FROM low_income)
) AS final_set
ORDER BY cs_order_number
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
