WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_manager,
        d.d_year,
        SUM(cs.cs_net_paid) AS catalog_sales,
        SUM(ss.ss_net_paid) AS store_sales
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
    JOIN tpcds.income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year IN (1999, 2000, 2001)
      AND cc.cc_manager = 'Richard James'
      AND ib.ib_lower_bound >= 50000
      AND ws.web_state = 'CA'
      AND cp.cp_type = 'P'
    GROUP BY cc.cc_call_center_id, cc.cc_manager, d.d_year
)
SELECT
    cc_manager,
    AVG(catalog_sales + store_sales) AS avg_total_sales
FROM sales_agg
GROUP BY cc_manager
HAVING AVG(catalog_sales + store_sales) > 10000
ORDER BY avg_total_sales DESC
