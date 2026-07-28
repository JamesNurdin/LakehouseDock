WITH
    ss_cte AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_customer_sk,
            ss.ss_hdemo_sk,
            ss.ss_promo_sk,
            ss.ss_item_sk,
            ss.ss_ticket_number,
            ss.ss_ext_sales_price
        FROM store_sales ss
        JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
        JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
        JOIN promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk
        WHERE d1.d_year = 2000
    ),
    agg AS (
        SELECT
            d_sold.d_year,
            cc.cc_name,
            sm.sm_type,
            p.p_promo_name,
            ws.web_name,
            d_sold.d_date_sk,
            SUM(cs.cs_ext_sales_price)                               AS catalog_sales_amount,
            SUM(ss_cte.ss_ext_sales_price)                          AS store_sales_amount,
            SUM(COALESCE(sr.sr_return_amt, 0))                      AS total_returns,
            (
                SELECT MAX(p2.p_cost)
                FROM promotion p2
                WHERE p2.p_start_date_sk = d_sold.d_date_sk
            )                                                        AS max_promo_cost_for_day
        FROM catalog_sales cs
        JOIN date_dim d_sold           ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_sold           ON cs.cs_sold_time_sk = t_sold.t_time_sk
        JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d_promo_start    ON p.p_start_date_sk = d_promo_start.d_date_sk
        JOIN date_dim d_promo_end      ON p.p_end_date_sk = d_promo_end.d_date_sk
        JOIN web_site ws               ON ws.web_open_date_sk = d_sold.d_date_sk
        JOIN customer c_bill           ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
        JOIN web_page wp               ON wp.wp_customer_sk = c_bill.c_customer_sk
        JOIN date_dim d_wp_create      ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
        JOIN date_dim d_wp_access      ON wp.wp_access_date_sk = d_wp_access.d_date_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN ss_cte                    ON ss_cte.ss_item_sk = cs.cs_item_sk
        LEFT JOIN store_returns sr    ON sr.sr_item_sk = cs.cs_item_sk
                                    AND sr.sr_ticket_number = cs.cs_order_number
        GROUP BY
            d_sold.d_year,
            cc.cc_name,
            sm.sm_type,
            p.p_promo_name,
            ws.web_name,
            d_sold.d_date_sk
    )
SELECT
    d_year,
    cc_name,
    sm_type,
    p_promo_name,
    web_name,
    catalog_sales_amount,
    store_sales_amount,
    total_returns,
    (catalog_sales_amount + store_sales_amount - total_returns)               AS net_sales,
    max_promo_cost_for_day,
    SUM(catalog_sales_amount + store_sales_amount) OVER (PARTITION BY d_year) AS year_total_sales,
    RANK() OVER (PARTITION BY d_year ORDER BY (catalog_sales_amount + store_sales_amount - total_returns) DESC) AS sales_rank
FROM agg
ORDER BY d_year, net_sales DESC
LIMIT 100
