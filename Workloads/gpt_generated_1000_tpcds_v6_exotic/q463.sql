WITH ss_base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_time_sk,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17                -- business hours filter
),
catalog_sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_ext_list_price,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
)
SELECT
    s.s_store_name,
    s.s_state,
    td2.t_hour,
    SUM(ssb.ss_ext_sales_price)                                   AS store_sales_total,
    SUM(ws.ws_ext_sales_price)                                     AS web_sales_total,
    SUM(csa.cs_ext_sales_price)                                    AS catalog_sales_total,
    AVG(sr.sr_return_amt_inc_tax)                                 AS avg_store_return_inc_tax,
    COUNT(DISTINCT ssb.ss_ticket_number)                           AS distinct_store_orders,
    (SELECT SUM(cs2.cs_ext_sales_price) FROM tpcds.catalog_sales cs2) AS global_catalog_sales_sum
FROM ss_base ssb
JOIN tpcds.time_dim td2
    ON ssb.ss_sold_time_sk = td2.t_time_sk
JOIN tpcds.store s
    ON ssb.ss_store_sk = s.s_store_sk
JOIN tpcds.customer c
    ON ssb.ss_customer_sk = c.c_customer_sk
JOIN tpcds.household_demographics hd
    ON ssb.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.customer_address ca
    ON ssb.ss_addr_sk = ca.ca_address_sk
JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ssb.ss_ticket_number
JOIN tpcds.reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.catalog_sales csa
    ON csa.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.call_center cc
    ON csa.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = csa.cs_order_number
   AND cr.cr_item_sk = csa.cs_item_sk
JOIN tpcds.web_sales ws
    ON ws.ws_sold_time_sk = ssb.ss_sold_time_sk
JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN tpcds.web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
WHERE s.s_state = 'CA'                                          -- store location filter
  AND wsite.web_country = 'United States'                        -- website country filter
  AND ca.ca_state = 'CA'                                          -- customer address filter
GROUP BY
    s.s_store_name,
    s.s_state,
    td2.t_hour
ORDER BY
    store_sales_total DESC
LIMIT 100
