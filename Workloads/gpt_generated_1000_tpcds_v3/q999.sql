WITH joined_data AS (
    SELECT
        d.d_year AS d_year,
        cp.cp_catalog_page_sk AS cp_catalog_page_sk,
        cp.cp_catalog_page_number AS cp_catalog_page_number,
        cp.cp_department AS cp_department,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_net_profit AS cs_net_profit,
        cr.cr_return_amount AS cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        p.p_discount_active AS p_discount_active,
        w.w_state AS w_state,
        cd.cd_education_status AS cd_education_status,
        hd.hd_vehicle_count AS hd_vehicle_count,
        i.inv_quantity_on_hand AS inv_quantity_on_hand,
        r.r_reason_desc AS r_reason_desc,
        ss.ss_net_paid AS store_net_paid,
        ws.ws_net_paid AS web_net_paid,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        sm.sm_type AS cs_ship_type,
        sm_cr.sm_type AS cr_ship_type
    FROM date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr ON cs.cs_item_sk = cr.cr_item_sk AND cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk AND i.inv_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Books'
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND cd.cd_education_status = 'Advanced Degree'
      AND hd.hd_vehicle_count > 0
      AND i.inv_quantity_on_hand > 0
      AND (r.r_reason_desc IS NULL OR r.r_reason_desc NOT LIKE '%damage%')
),
agg_data AS (
    SELECT
        d_year,
        cp_catalog_page_sk,
        cp_catalog_page_number,
        cp_department,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(COALESCE(cr_return_amount, 0)) AS total_returns,
        SUM(cs_net_profit) AS total_sales_profit,
        SUM(COALESCE(cr_net_loss, 0)) AS total_return_loss,
        SUM(COALESCE(store_net_paid, 0)) AS total_store_sales,
        SUM(COALESCE(web_net_paid, 0)) AS total_web_sales
    FROM joined_data
    GROUP BY d_year, cp_catalog_page_sk, cp_catalog_page_number, cp_department
    HAVING SUM(cs_ext_sales_price) > 10000
)
SELECT
    d_year,
    cp_catalog_page_sk,
    cp_catalog_page_number,
    cp_department,
    total_sales,
    total_returns,
    (total_sales_profit - total_return_loss) AS net_profit,
    total_store_sales,
    total_web_sales,
    RANK() OVER (PARTITION BY d_year ORDER BY (total_sales_profit - total_return_loss) DESC) AS profit_rank,
    CASE WHEN (total_sales_profit - total_return_loss) > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_status
FROM agg_data
ORDER BY profit_rank, net_profit DESC
LIMIT 100
