WITH enriched AS (
   SELECT
       c.c_customer_id,
       c.c_customer_sk,
       ca.ca_state,
       cd.cd_gender,
       st.s_store_name,
       ss.ss_ticket_number,
       ss.ss_ext_sales_price,
       ss.ss_net_profit,
       t.t_hour,
       promo.p_promo_id,
       promo.p_channel_details,
       cp.cp_department,
       wh.w_warehouse_name,
       wp.wp_url,
       r1.r_reason_desc   AS store_return_reason,
       r2.r_reason_desc   AS catalog_return_reason,
       r3.r_reason_desc   AS web_return_reason,
       inv.inv_quantity_on_hand
   FROM customer c
   JOIN customer_address ca
       ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd
       ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN store_sales ss
       ON ss.ss_customer_sk = c.c_customer_sk
   LEFT JOIN time_dim t
       ON ss.ss_sold_time_sk = t.t_time_sk
   LEFT JOIN promotion promo
       ON ss.ss_promo_sk = promo.p_promo_sk
   LEFT JOIN store st
       ON ss.ss_store_sk = st.s_store_sk
   LEFT JOIN store_returns sr
       ON sr.sr_customer_sk = c.c_customer_sk
   LEFT JOIN reason r1
       ON sr.sr_reason_sk = r1.r_reason_sk
   LEFT JOIN catalog_returns cr
       ON cr.cr_refunded_customer_sk = c.c_customer_sk
   LEFT JOIN catalog_page cp
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN warehouse wh
       ON cr.cr_warehouse_sk = wh.w_warehouse_sk
   LEFT JOIN reason r2
       ON cr.cr_reason_sk = r2.r_reason_sk
   LEFT JOIN web_returns wr
       ON wr.wr_refunded_customer_sk = c.c_customer_sk
   LEFT JOIN web_page wp
       ON wr.wr_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN reason r3
       ON wr.wr_reason_sk = r3.r_reason_sk
   LEFT JOIN inventory inv
       ON inv.inv_warehouse_sk = wh.w_warehouse_sk
)
SELECT
   e.c_customer_id,
   e.ca_state,
   e.cd_gender,
   e.s_store_name,
   COUNT(DISTINCT e.ss_ticket_number)                         AS distinct_sales,
   SUM(DISTINCT e.ss_ext_sales_price)                         AS sum_distinct_sales,
   COUNT(DISTINCT e.store_return_reason)                     AS distinct_store_return_reasons,
   COUNT(DISTINCT e.catalog_return_reason)                   AS distinct_catalog_return_reasons,
   COUNT(DISTINCT e.web_return_reason)                       AS distinct_web_return_reasons,
   CASE WHEN SUM(DISTINCT e.ss_ext_sales_price) > 1000 THEN 'High' ELSE 'Low' END AS sales_volume_category,
   COUNT(DISTINCT word)                                       AS distinct_promo_words
FROM enriched e
CROSS JOIN UNNEST(split(e.p_channel_details, ' ')) AS t(word)
WHERE e.c_customer_sk NOT IN (
    SELECT DISTINCT cr_refunded_customer_sk
    FROM catalog_returns
    WHERE cr_return_amount > 5000
)
GROUP BY
   e.c_customer_id,
   e.ca_state,
   e.cd_gender,
   e.s_store_name,
   e.p_channel_details
ORDER BY sum_distinct_sales DESC
LIMIT 100
