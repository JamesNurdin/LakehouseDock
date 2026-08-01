SELECT
    s.s_store_name,
    cc.cc_name,
    sm.sm_type,
    promo_cs.p_promo_name AS catalog_promo_name,
    d_sales.d_year,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_catalog_items,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(wr.wr_net_loss) AS total_return_loss,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_indicator,
    (SELECT COUNT(DISTINCT r_sub.r_reason_id) FROM reason r_sub) AS total_reason_types
FROM
    catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion promo_cs ON cs.cs_promo_sk = promo_cs.p_promo_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_promo_start ON promo_cs.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON promo_cs.p_end_date_sk = d_promo_end.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion promo_ss ON ss.ss_promo_sk = promo_ss.p_promo_sk
    JOIN inventory inv ON inv.inv_date_sk = d_sales.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_sales.d_date_sk
    JOIN time_dim t_return ON wr.wr_returned_time_sk = t_return.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer cust_refund ON wr.wr_refunded_customer_sk = cust_refund.c_customer_sk
    JOIN customer cust_returning ON wr.wr_returning_customer_sk = cust_returning.c_customer_sk
GROUP BY
    s.s_store_name,
    cc.cc_name,
    sm.sm_type,
    promo_cs.p_promo_name,
    d_sales.d_year
ORDER BY
    total_catalog_net_paid DESC
LIMIT 100
