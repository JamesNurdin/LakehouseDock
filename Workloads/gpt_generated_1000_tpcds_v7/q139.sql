WITH overall_avg_price AS (
    SELECT AVG(i3.i_current_price) AS avg_price
    FROM tpcds.item i3
)
SELECT
    s.s_store_name,
    d.d_year,
    ib.ib_income_band_sk,
    COUNT(DISTINCT cd.cd_demo_sk) AS customer_demo_count,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    AVG(i.i_current_price) AS avg_item_price,
    (SELECT avg_price FROM overall_avg_price) AS overall_avg_item_price
FROM tpcds.date_dim d
INNER JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
INNER JOIN tpcds.item i
    ON ss.ss_item_sk = i.i_item_sk
INNER JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
INNER JOIN tpcds.customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
INNER JOIN tpcds.customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
INNER JOIN tpcds.household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
INNER JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
INNER JOIN tpcds.warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
INNER JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_store_sk = s.s_store_sk
INNER JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
INNER JOIN tpcds.web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
INNER JOIN tpcds.web_site ws
    ON wp.wp_creation_date_sk = ws.web_open_date_sk
INNER JOIN tpcds.call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
INNER JOIN tpcds.catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND s.s_state = 'CA'
    AND ib.ib_upper_bound <= 150000
    AND wp.wp_char_count > 3000
    AND cp.cp_department = 'Electronics'
GROUP BY
    s.s_store_name,
    d.d_year,
    ib.ib_income_band_sk
ORDER BY
    total_sales DESC
LIMIT 100
