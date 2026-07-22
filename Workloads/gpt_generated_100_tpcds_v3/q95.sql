/*
  Goal: Analyze catalog sales performance for the year 2000, ranking customers by net profit while incorporating related catalog, store, and web return information, and categorizing profit status.
*/
SELECT
    cs.cs_order_number,
    d.d_date,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    cp.cp_department,
    cp.cp_description,
    w.w_warehouse_name,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    RANK() OVER (PARTITION BY d.d_year ORDER BY cs.cs_net_profit DESC) AS profit_rank_year,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.cs_net_paid_inc_tax DESC) AS rn_customer_sales
FROM
    catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 2000
    AND cs.cs_quantity > 1
    AND ib.ib_upper_bound > 50000
ORDER BY
    profit_rank_year,
    cs.cs_net_paid_inc_tax DESC
LIMIT 100
