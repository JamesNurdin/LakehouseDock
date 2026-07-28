WITH daily_agg AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_date AS sales_date,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(sr.sr_return_amt_inc_tax) AS total_store_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_returns,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(cs.cs_net_profit) AS total_profit
    FROM tpcds.date_dim d
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
                                 AND cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND cc.cc_gmt_offset BETWEEN -5 AND 0
      AND c.c_preferred_cust_flag = 'Y'
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 2
    GROUP BY s.s_store_id, d.d_date
)
SELECT
    store_id,
    AVG(total_sales) AS avg_daily_sales,
    AVG(total_profit) AS avg_daily_profit,
    SUM(total_store_returns) AS sum_store_returns,
    SUM(total_web_returns) AS sum_web_returns,
    SUM(total_catalog_returns) AS sum_catalog_returns
FROM daily_agg
GROUP BY store_id
HAVING AVG(total_sales) > 1000
ORDER BY avg_daily_sales DESC
LIMIT 100
