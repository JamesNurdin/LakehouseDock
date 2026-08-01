WITH
    base AS (
        SELECT
            d_sold.d_year,
            i.i_category,
            i.i_class,
            s.s_store_name,
            c_bill.c_customer_id,
            cs.cs_ext_sales_price AS catalog_sales_price,
            ss.ss_ext_sales_price AS store_sales_price,
            wr.wr_return_amt AS return_amount,
            cs.cs_net_profit AS catalog_net_profit,
            ss.ss_net_profit AS store_net_profit,
            wr.wr_net_loss AS return_net_loss,
            p.p_promo_id,
            sm.sm_type,
            r.r_reason_desc,
            wp.wp_url,
            cp.cp_catalog_number,
            t_sold.t_hour AS cs_hour,
            t_ss.t_hour AS ss_hour,
            t_wr.t_hour AS wr_hour
        FROM catalog_sales cs
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        JOIN date_dim d_sold
            ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_sold
            ON cs.cs_sold_time_sk = t_sold.t_time_sk
        JOIN date_dim d_ship
            ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN customer c_bill
            ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
        JOIN customer_demographics cd_bill
            ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_address ca_bill
            ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer c_ship
            ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
        JOIN customer_demographics cd_ship
            ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN customer_address ca_ship
            ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        -- store sales and related dimensions
        LEFT JOIN store_sales ss
            ON ss.ss_item_sk = i.i_item_sk
           AND ss.ss_sold_date_sk = d_sold.d_date_sk
        LEFT JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN time_dim t_ss
            ON ss.ss_sold_time_sk = t_ss.t_time_sk
        LEFT JOIN date_dim d_store_closed
            ON s.s_closed_date_sk = d_store_closed.d_date_sk
        -- web returns and related dimensions
        LEFT JOIN web_returns wr
            ON wr.wr_item_sk = i.i_item_sk
           AND wr.wr_returned_date_sk = d_sold.d_date_sk
        LEFT JOIN reason r
            ON wr.wr_reason_sk = r.r_reason_sk
        LEFT JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN time_dim t_wr
            ON wr.wr_returned_time_sk = t_wr.t_time_sk
        LEFT JOIN date_dim d_wp_creation
            ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
        LEFT JOIN date_dim d_wp_access
            ON wp.wp_access_date_sk = d_wp_access.d_date_sk
        LEFT JOIN customer c_wp
            ON wp.wp_customer_sk = c_wp.c_customer_sk
        -- catalog page date dimensions
        LEFT JOIN date_dim d_cp_start
            ON cp.cp_start_date_sk = d_cp_start.d_date_sk
        LEFT JOIN date_dim d_cp_end
            ON cp.cp_end_date_sk = d_cp_end.d_date_sk
        -- promotion date dimensions
        LEFT JOIN date_dim d_promo_start
            ON p.p_start_date_sk = d_promo_start.d_date_sk
        LEFT JOIN date_dim d_promo_end
            ON p.p_end_date_sk = d_promo_end.d_date_sk
        -- current customer attributes for the billing customer
        LEFT JOIN customer_demographics cd_cust
            ON c_bill.c_current_cdemo_sk = cd_cust.cd_demo_sk
        LEFT JOIN customer_address ca_cust
            ON c_bill.c_current_addr_sk = ca_cust.ca_address_sk
    ),
    agg AS (
        SELECT
            d_year,
            i_category,
            i_class,
            s_store_name,
            COUNT(DISTINCT c_customer_id) AS distinct_customers,
            SUM(COALESCE(store_sales_price, 0) + COALESCE(catalog_sales_price, 0) - COALESCE(return_amount, 0)) AS total_sales,
            SUM(COALESCE(store_net_profit, 0) + COALESCE(catalog_net_profit, 0) - COALESCE(return_net_loss, 0)) AS total_profit
        FROM base
        GROUP BY ROLLUP (i_category, i_class, d_year, s_store_name)
    )
SELECT
    d_year,
    i_category,
    i_class,
    s_store_name,
    total_sales,
    total_profit,
    distinct_customers,
    SUM(total_sales) OVER (
        PARTITION BY i_category
        ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_sales,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS rank_by_sales
FROM agg
ORDER BY i_category, i_class, d_year, s_store_name
