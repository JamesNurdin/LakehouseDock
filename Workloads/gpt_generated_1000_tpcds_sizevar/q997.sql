WITH base AS (
   SELECT
       cs.cs_order_number,
       cs.cs_net_paid,
       d_cs.d_year AS d_year,
       d_cs.d_month_seq AS d_month_seq,
       cp.cp_description,
       split(cp.cp_description, ' ') AS desc_words,
       sm.sm_type,
       hd_bill.hd_vehicle_count,
       cc.cc_name,
       wp.wp_url,
       inv.inv_quantity_on_hand,
       st.s_store_name
   FROM tpcds.catalog_sales cs TABLESAMPLE BERNOULLI (10)
   JOIN tpcds.date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
   JOIN tpcds.time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
   JOIN tpcds.customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
   JOIN tpcds.customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN tpcds.household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN tpcds.customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
   JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   JOIN tpcds.date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
   JOIN tpcds.time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
   JOIN tpcds.web_sales ws ON ws.ws_order_number = cs.cs_order_number
   JOIN tpcds.date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
   JOIN tpcds.time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
   JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
   JOIN tpcds.inventory inv ON inv.inv_date_sk = d_cs.d_date_sk
   JOIN tpcds.store st ON st.s_closed_date_sk = d_cs.d_date_sk
   WHERE d_cs.d_year = 2001
     AND hd_bill.hd_vehicle_count > 1
     AND sm.sm_type = 'AIR'
     AND EXISTS (
         SELECT 1
         FROM tpcds.web_sales ws2
         WHERE ws2.ws_order_number = cs.cs_order_number
           AND ws2.ws_net_paid > (SELECT AVG(ws_net_paid) FROM tpcds.web_sales)
     )
)
SELECT
    d_year,
    d_month_seq,
    total_net_paid,
    distinct_word_cnt,
    year_rank,
    grand_total
FROM (
    SELECT
        d_year,
        d_month_seq,
        SUM(cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT w) AS distinct_word_cnt,
        RANK() OVER (PARTITION BY d_year ORDER BY SUM(cs_net_paid) DESC) AS year_rank,
        SUM(SUM(cs_net_paid)) OVER () AS grand_total
    FROM base
    CROSS JOIN UNNEST(desc_words) AS t(w)
    GROUP BY ROLLUP (d_year, d_month_seq)
) t
ORDER BY d_year, d_month_seq
LIMIT 100
