SELECT
    s.s_store_name,
    dd_sold.d_year,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_bill_customers,
    (SELECT MAX(p_cost) FROM promotion) AS max_promo_cost
FROM catalog_sales cs
INNER JOIN date_dim dd_sold
    ON cs.cs_sold_date_sk = dd_sold.d_date_sk
INNER JOIN date_dim dd_ship
    ON cs.cs_ship_date_sk = dd_ship.d_date_sk
INNER JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
INNER JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
INNER JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
INNER JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN promotion promo_cs
    ON cs.cs_promo_sk = promo_cs.p_promo_sk
INNER JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
INNER JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
   AND inv.inv_date_sk = dd_sold.d_date_sk
INNER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
INNER JOIN store_sales ss
    ON ss.ss_sold_date_sk = dd_sold.d_date_sk
INNER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
FULL OUTER JOIN date_dim dd_close
    ON s.s_closed_date_sk = dd_close.d_date_sk
INNER JOIN web_page wp
    ON wp.wp_customer_sk = c_bill.c_customer_sk
LEFT JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
LEFT JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
LEFT JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN promotion promo_ss
    ON ss.ss_promo_sk = promo_ss.p_promo_sk
LEFT JOIN customer c_ship
    ON ss.ss_customer_sk = c_ship.c_customer_sk
GROUP BY
    s.s_store_name,
    dd_sold.d_year
ORDER BY total_catalog_sales DESC
LIMIT 100
