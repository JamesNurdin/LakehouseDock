/*
  Goal: Compute yearly total sales and return amounts per customer and department, count distinct promotions used, and rank customers by sales within each year, joining all TPC‑DS tables.
*/
WITH joined AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        d_sales.d_year AS sales_year,
        cp.cp_department AS department,
        ss.ss_ext_sales_price AS sales_amount,
        sr.sr_return_amt AS store_return_amount,
        cr.cr_return_amount AS catalog_return_amount,
        wr.wr_return_amt AS web_return_amount,
        p.p_promo_name AS promo_name
    FROM store_sales ss
    /* core sales dimensions */
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd_customer ON ss.ss_cdemo_sk = cd_customer.cd_demo_sk
    JOIN household_demographics hd_customer ON ss.ss_hdemo_sk = hd_customer.hd_demo_sk
    JOIN customer_address ca_customer ON ss.ss_addr_sk = ca_customer.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    /* promotion date dimensions */
    JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
    JOIN date_dim d_p_end   ON p.p_end_date_sk   = d_p_end.d_date_sk
    /* store returns */
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    /* catalog returns */
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sales.d_date_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end   ON cp.cp_end_date_sk   = d_cp_end.d_date_sk
    JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer c_return ON cr.cr_returning_customer_sk = c_return.c_customer_sk
    JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN customer_demographics cd_return ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN household_demographics hd_return ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    /* web returns */
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_sales.d_date_sk
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN customer c_wr_refund ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
    JOIN customer c_wr_return ON wr.wr_returning_customer_sk = c_wr_return.c_customer_sk
    JOIN customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
    JOIN customer_demographics cd_wr_return ON wr.wr_returning_cdemo_sk = cd_wr_return.cd_demo_sk
    JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
    JOIN household_demographics hd_wr_return ON wr.wr_returning_hdemo_sk = hd_wr_return.hd_demo_sk
    JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
    JOIN customer_address ca_wr_return ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
    /* web site */
    JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
    JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
)
,
aggregated AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        sales_year,
        department,
        SUM(sales_amount)              AS total_sales,
        SUM(store_return_amount)       AS total_store_return,
        SUM(catalog_return_amount)    AS total_catalog_return,
        SUM(web_return_amount)        AS total_web_return,
        COUNT(DISTINCT promo_name)    AS distinct_promos
    FROM joined
    GROUP BY
        customer_id,
        first_name,
        last_name,
        sales_year,
        department
)
SELECT
    customer_id,
    first_name,
    last_name,
    sales_year,
    department,
    total_sales,
    total_store_return,
    total_catalog_return,
    total_web_return,
    distinct_promos,
    ROW_NUMBER() OVER (PARTITION BY sales_year ORDER BY total_sales DESC) AS sales_rank_year
FROM aggregated
ORDER BY sales_year, sales_rank_year
LIMIT 100
