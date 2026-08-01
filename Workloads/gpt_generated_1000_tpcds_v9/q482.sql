WITH fact_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(wr.wr_return_amt) AS total_web_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS unique_store_txns,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
        JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
        JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
        JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
            AND cr.cr_returned_time_sk = t.t_time_sk
            AND cr.cr_item_sk = i.i_item_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
            AND wr.wr_returned_time_sk = t.t_time_sk
            AND wr.wr_item_sk = i.i_item_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = i.i_item_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
            AND wr.wr_reason_sk = r.r_reason_sk
        JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
        JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    WHERE
        d.d_year = 2001
        AND t.t_meal_time = 'lunch'
        AND i.i_brand = 'Brand#23'
        AND w.w_state = 'CA'
        AND sm.sm_type = 'AIR'
    GROUP BY
        d.d_year,
        i.i_category
    HAVING
        SUM(ss.ss_ext_sales_price) > 100000
        AND SUM(cr.cr_return_amount) > 5000
        AND SUM(wr.wr_return_amt) > 2000
)
SELECT
    d_year,
    i_category,
    total_store_sales,
    total_catalog_returns,
    total_web_returns,
    unique_store_txns,
    profit_category,
    total_store_sales / NULLIF(unique_store_txns, 0) AS avg_sales_per_txn
FROM fact_agg
ORDER BY total_store_sales DESC
LIMIT 100
