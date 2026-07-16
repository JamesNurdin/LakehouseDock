WITH
store_sales_agg AS (
 SELECT i.i_item_sk,
        i.i_product_name,
        d.d_year,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_ext_tax) AS total_tax,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_count
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
 WHERE d.d_year = 2000
 GROUP BY i.i_item_sk, i.i_product_name, d.d_year
),
catalog_sales_agg AS (
 SELECT i.i_item_sk,
        i.i_product_name,
        d.d_year,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_ext_tax) AS total_tax,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 WHERE d.d_year = 2000
 GROUP BY i.i_item_sk, i.i_product_name, d.d_year
),
web_sales_agg AS (
 SELECT i.i_item_sk,
        i.i_product_name,
        d.d_year,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
 LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
 WHERE d.d_year = 2000
 GROUP BY i.i_item_sk, i.i_product_name, d.d_year
)
SELECT
   item_sk,
   product_name,
   sales_year,
   channel,
   total_net_profit,
   total_quantity,
   total_sales,
   total_discount,
   total_tax,
   order_count,
   rank
FROM (
   SELECT
       combined.*,
       ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_net_profit DESC) AS rank
   FROM (
       SELECT
           i_item_sk AS item_sk,
           i_product_name AS product_name,
           d_year AS sales_year,
           channel,
           total_net_profit,
           total_quantity,
           total_sales,
           total_discount,
           total_tax,
           order_count
       FROM store_sales_agg
       UNION ALL
       SELECT
           i_item_sk AS item_sk,
           i_product_name AS product_name,
           d_year AS sales_year,
           channel,
           total_net_profit,
           total_quantity,
           total_sales,
           total_discount,
           total_tax,
           order_count
       FROM catalog_sales_agg
       UNION ALL
       SELECT
           i_item_sk AS item_sk,
           i_product_name AS product_name,
           d_year AS sales_year,
           channel,
           total_net_profit,
           total_quantity,
           total_sales,
           total_discount,
           total_tax,
           order_count
       FROM web_sales_agg
   ) AS combined
) AS ranked
WHERE rank <= 10
ORDER BY channel, rank
