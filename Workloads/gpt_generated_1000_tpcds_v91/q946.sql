WITH fact1 AS (
   SELECT
       d.d_year AS year,
       i.i_brand AS brand,
       p_cat.p_promo_name AS promotion_name,
       SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
       SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns,
       SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_web_sales,
       SUM(COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(sr.sr_net_loss, 0)) AS net_profit,
       (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_brand = i.i_brand) AS max_brand_price
   FROM catalog_sales cs
   JOIN date_dim d
       ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i
       ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p_cat
       ON cs.cs_promo_sk = p_cat.p_promo_sk
   JOIN customer_demographics cd
       ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca
       ON cs.cs_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN store_returns sr
       ON sr.sr_returned_date_sk = d.d_date_sk
          AND sr.sr_item_sk = i.i_item_sk
   LEFT JOIN customer_demographics cd_sr
       ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
   LEFT JOIN customer_address ca_sr
       ON sr.sr_addr_sk = ca_sr.ca_address_sk
   LEFT JOIN web_sales ws
       ON ws.ws_sold_date_sk = d.d_date_sk
          AND ws.ws_item_sk = i.i_item_sk
   LEFT JOIN promotion p_ws
       ON ws.ws_promo_sk = p_ws.p_promo_sk
   LEFT JOIN web_page wp
       ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN date_dim d_wp_creation
       ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
   WHERE EXISTS (
       SELECT 1 FROM promotion p_filter
       WHERE p_filter.p_item_sk = i.i_item_sk
         AND p_filter.p_channel_tv = 'Y'
   )
   GROUP BY d.d_year, i.i_brand, p_cat.p_promo_name
   HAVING SUM(cs.cs_ext_sales_price) > 10000
),
fact2 AS (
   SELECT
       d2.d_year AS year,
       i2.i_brand AS brand,
       p2.p_promo_name AS promotion_name,
       CAST(0 AS decimal(7,2)) AS total_catalog_sales,
       SUM(COALESCE(sr2.sr_return_amt, 0)) AS total_store_returns,
       SUM(COALESCE(ws2.ws_ext_sales_price, 0)) AS total_web_sales,
       SUM(COALESCE(ws2.ws_net_profit, 0) - COALESCE(sr2.sr_net_loss, 0)) AS net_profit,
       (SELECT MAX(i3.i_current_price) FROM item i3 WHERE i3.i_brand = i2.i_brand) AS max_brand_price
   FROM web_sales ws2
   JOIN date_dim d2
       ON ws2.ws_sold_date_sk = d2.d_date_sk
   JOIN item i2
       ON ws2.ws_item_sk = i2.i_item_sk
   JOIN promotion p2
       ON ws2.ws_promo_sk = p2.p_promo_sk
   JOIN customer_demographics cd2
       ON ws2.ws_bill_cdemo_sk = cd2.cd_demo_sk
   JOIN customer_address ca2
       ON ws2.ws_bill_addr_sk = ca2.ca_address_sk
   JOIN web_page wp2
       ON ws2.ws_web_page_sk = wp2.wp_web_page_sk
   JOIN date_dim d_wp2_creation
       ON wp2.wp_creation_date_sk = d_wp2_creation.d_date_sk
   LEFT JOIN store_returns sr2
       ON sr2.sr_returned_date_sk = d2.d_date_sk
          AND sr2.sr_item_sk = i2.i_item_sk
   WHERE EXISTS (
       SELECT 1 FROM promotion p_filter2
       WHERE p_filter2.p_item_sk = i2.i_item_sk
         AND p_filter2.p_channel_radio = 'Y'
   )
   GROUP BY d2.d_year, i2.i_brand, p2.p_promo_name
   HAVING SUM(ws2.ws_ext_sales_price) > 5000
),
unioned AS (
   SELECT * FROM fact1
   UNION DISTINCT
   SELECT * FROM fact2
)
SELECT
   year,
   brand,
   promotion_name,
   total_catalog_sales,
   total_store_returns,
   total_web_sales,
   net_profit,
   max_brand_price,
   ROW_NUMBER() OVER (PARTITION BY year ORDER BY net_profit DESC) AS profit_rank
FROM unioned
ORDER BY net_profit DESC, year
LIMIT 100
