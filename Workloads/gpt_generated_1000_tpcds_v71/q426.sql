WITH base_sales AS (
    SELECT
        s.s_state AS s_state,
        i.i_category AS i_category,
        cs.cs_order_number AS cs_order_number,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_ext_discount_amt AS cs_ext_discount_amt,
        sm.sm_type AS sm_type,
        i.i_item_sk AS i_item_sk,
        s.s_store_sk AS s_store_sk
    FROM tpcds.time_dim td
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN tpcds.item i
        ON i.i_item_sk = cs.cs_item_sk
    JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    JOIN tpcds.customer_address ca
        ON ca.ca_address_sk = cs.cs_bill_addr_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN tpcds.store s
        ON s.s_store_sk = ss.ss_store_sk
    JOIN tpcds.web_site wsite
        ON wsite.web_site_sk = ws.ws_web_site_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
      AND s.s_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cd.cd_credit_rating = 'Good'
)
SELECT
    s_state,
    i_category,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN sm_type = 'AIR' THEN cs_ext_sales_price ELSE 0 END) AS air_sales
FROM base_sales bs
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.store_returns sr2
    WHERE sr2.sr_item_sk = bs.i_item_sk
      AND sr2.sr_store_sk = bs.s_store_sk
)
GROUP BY GROUPING SETS (
    (s_state, i_category),
    (s_state),
    (i_category),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
