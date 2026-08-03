WITH cte_sales AS (
    SELECT
        p.p_promo_id AS promo_id,
        s.s_store_id AS store_id,
        d_sold.d_year AS sales_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(wr.wr_return_amt) AS total_web_returns,
        COUNT(DISTINCT r.r_reason_desc) AS distinct_return_reasons
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_sold.d_date_sk
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN household_demographics hd_wr_refund
        ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
    JOIN household_demographics hd_wr_returning
        ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    WHERE d_sold.d_year = 2001
      AND p.p_cost > 100
      AND s.s_state = 'CA'
    GROUP BY p.p_promo_id, s.s_store_id, d_sold.d_year
)
SELECT
    promo_id,
    AVG(total_sales) AS avg_sales_per_store,
    SUM(total_catalog_returns) AS sum_catalog_returns,
    COUNT(DISTINCT store_id) AS store_count
FROM cte_sales
GROUP BY promo_id
ORDER BY avg_sales_per_store DESC
LIMIT 100
