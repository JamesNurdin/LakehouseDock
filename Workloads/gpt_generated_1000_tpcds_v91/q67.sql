WITH base AS (
    SELECT
        d_sold.d_year AS d_year,
        ca_bill.ca_state AS ca_state,
        ib.ib_income_band_sk AS ib_income_band_sk,
        cs.cs_net_paid AS cs_net_paid,
        cr.cr_return_amount AS cr_return_amount,
        sr.sr_return_amt AS sr_return_amt,
        wr.wr_return_amt AS wr_return_amt,
        cs.cs_order_number AS cs_order_number,
        cs.cs_quantity AS cs_quantity
    FROM catalog_sales cs
    INNER JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    LEFT JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    INNER JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    INNER JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    INNER JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    INNER JOIN inventory inv
        ON inv.inv_date_sk = d_ship.d_date_sk
       AND inv.inv_item_sk = cs.cs_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN household_demographics hd_cr_refunded
        ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
    LEFT JOIN customer_address ca_cr_refunded
        ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
    LEFT JOIN household_demographics hd_cr_returning
        ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
    LEFT JOIN customer_address ca_cr_returning
        ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
    LEFT JOIN catalog_page cp_cr
        ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
    LEFT JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN date_dim d_store
        ON TRUE
    LEFT JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd_bill.hd_demo_sk
       AND sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN time_dim t_store
        ON sr.sr_return_time_sk = t_store.t_time_sk
    LEFT JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    LEFT JOIN date_dim d_web
        ON TRUE
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd_bill.hd_demo_sk
       AND wr.wr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN time_dim t_web
        ON wr.wr_returned_time_sk = t_web.t_time_sk
    LEFT JOIN household_demographics hd_wr_refunded
        ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    LEFT JOIN customer_address ca_wr_refunded
        ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    LEFT JOIN household_demographics hd_wr_returning
        ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    LEFT JOIN customer_address ca_wr_returning
        ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE d_sold.d_year = 2001
      AND ca_bill.ca_city = 'Fairview'
      AND hd_bill.hd_vehicle_count > 0
      AND p.p_discount_active = 'N'
)
SELECT
    d_year,
    ca_state,
    ib_income_band_sk,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(sr_return_amt) AS total_store_return,
    SUM(wr_return_amt) AS total_web_return,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(cs_quantity) AS avg_quantity,
    (SELECT SUM(p_sub.p_cost) FROM promotion p_sub WHERE p_sub.p_discount_active = 'N') AS total_active_promo_cost,
    ROW_NUMBER() OVER (ORDER BY d_year, ca_state, ib_income_band_sk) AS row_num
FROM base
GROUP BY ROLLUP (d_year, ca_state, ib_income_band_sk)
ORDER BY d_year, ca_state, ib_income_band_sk
LIMIT 100
