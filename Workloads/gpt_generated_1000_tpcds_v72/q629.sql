WITH base AS (
    SELECT
        d.d_year,
        i.i_brand,
        cp.cp_department,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_order_number AS cs_order_number,
        cs.cs_ext_discount_amt AS cs_ext_discount_amt,
        cs.cs_sold_date_sk AS cs_sold_date_sk
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_size = 'large'
      AND ca.ca_state = 'TX'
      AND ib.ib_lower_bound >= 70000
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND s.s_state = 'CA'
)
SELECT
    d_year,
    i_brand,
    cp_department,
    profit_flag,
    SUM(cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs_order_number) AS num_orders,
    AVG(cs_ext_discount_amt) AS avg_discount,
    MIN(cs_sold_date_sk) AS min_sold_date_sk,
    MAX(cs_sold_date_sk) AS max_sold_date_sk
FROM base
GROUP BY d_year, i_brand, cp_department, profit_flag
HAVING SUM(cs_net_profit) > 10000
LIMIT 100
