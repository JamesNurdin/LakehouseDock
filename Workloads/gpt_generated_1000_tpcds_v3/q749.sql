WITH
    filtered_sales AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_ship_mode_sk,
            cs.cs_warehouse_sk,
            cs.cs_promo_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_order_number,
            cs.cs_net_paid_inc_ship_tax,
            cs.cs_net_profit
        FROM catalog_sales cs
        WHERE cs.cs_net_paid_inc_ship_tax > 10000
    ),
    sales_with_joins AS (
        SELECT
            s.s_store_id AS s_store_id,
            d_sold.d_year AS d_year,
            fs.cs_net_paid_inc_ship_tax,
            fs.cs_net_profit,
            sm.sm_carrier,
            cp.cp_type,
            cp.cp_catalog_number,
            t_sold.t_hour,
            hd.hd_vehicle_count,
            ib.ib_upper_bound,
            p.p_discount_active,
            s.s_state
        FROM filtered_sales fs
        JOIN date_dim d_sold
            ON fs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_sold
            ON fs.cs_sold_time_sk = t_sold.t_time_sk
        JOIN call_center cc
            ON fs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
            ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
            ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w
            ON fs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p
            ON fs.cs_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd
            ON fs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON fs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = d_sold.d_date_sk
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN catalog_returns cr
            ON cr.cr_order_number = fs.cs_order_number
        WHERE
            sm.sm_carrier = 'FEDEX'
            AND cp.cp_type = 'monthly'
            AND d_sold.d_year = 2001
            AND t_sold.t_hour BETWEEN 9 AND 17
            AND hd.hd_vehicle_count >= 2
            AND ib.ib_upper_bound >= 60000
            AND s.s_state = 'CA'
            AND p.p_discount_active = 'Y'
            AND cp.cp_catalog_number IN (2, 11)
            AND EXISTS (
                SELECT 1
                FROM web_sales ws
                JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
                JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
                WHERE d_ws.d_date_sk = fs.cs_sold_date_sk
                  AND p_ws.p_promo_sk = fs.cs_promo_sk
                  AND ws.ws_quantity > 1
            )
    ),
    aggregated_sales AS (
        SELECT
            s_store_id,
            d_year,
            SUM(cs_net_paid_inc_ship_tax) AS total_sales,
            SUM(cs_net_profit) AS total_profit,
            COUNT(*) AS transaction_count
        FROM sales_with_joins
        GROUP BY s_store_id, d_year
    )
SELECT
    s_store_id,
    d_year,
    total_sales,
    total_profit,
    transaction_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
    CASE WHEN total_sales > 20000 THEN 'High' ELSE 'Medium' END AS sales_category
FROM aggregated_sales
ORDER BY d_year, sales_rank
