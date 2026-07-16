WITH unified_sales AS (
 SELECT ss.ss_sold_date_sk AS date_sk,
        ss.ss_store_sk AS store_sk,
        CAST(NULL AS integer) AS catalog_page_sk,
        CAST(NULL AS integer) AS web_page_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ticket_number AS order_number,
        'store' AS channel
 FROM store_sales ss
 UNION ALL
 SELECT cs.cs_sold_date_sk,
        CAST(NULL AS integer),
        cs.cs_catalog_page_sk,
        CAST(NULL AS integer),
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number,
        'catalog'
 FROM catalog_sales cs
 UNION ALL
 SELECT ws.ws_sold_date_sk,
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        ws.ws_web_page_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_order_number,
        'web'
 FROM web_sales ws
)
SELECT d.d_year,
       d.d_month_seq,
       us.channel,
       COALESCE(s.s_store_name, cp.cp_description, wp.wp_url) AS channel_desc,
       i.i_category,
       SUM(us.net_paid) AS total_sales,
       SUM(us.net_profit) AS total_profit,
       COUNT(DISTINCT us.order_number) AS orders,
       SUM(us.quantity) AS total_quantity,
       AVG(us.quantity) AS avg_quantity
FROM unified_sales us
JOIN date_dim d ON us.date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
LEFT JOIN store s ON us.store_sk = s.s_store_sk
LEFT JOIN catalog_page cp ON us.catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_page wp ON us.web_page_sk = wp.wp_web_page_sk
GROUP BY d.d_year,
         d.d_month_seq,
         us.channel,
         COALESCE(s.s_store_name, cp.cp_description, wp.wp_url),
         i.i_category
HAVING SUM(us.net_paid) > 0
ORDER BY total_sales DESC
LIMIT 100
