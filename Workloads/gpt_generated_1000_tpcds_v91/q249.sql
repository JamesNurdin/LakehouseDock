WITH store_data AS (
   SELECT
     ss.ss_sold_date_sk AS date_sk,
     ss.ss_item_sk AS item_sk,
     i.i_category,
     i.i_brand,
     i.i_product_name,
     ca.ca_state,
     cd.cd_gender,
     p.p_promo_name,
     ss.ss_quantity AS quantity,
     ss.ss_net_paid AS net_paid,
     ss.ss_net_profit AS net_profit,
     inv_max.max_quantity,
     cs.cs_net_paid AS catalog_net_paid,
     wr.wr_return_amt AS web_return_amt,
     ROW_NUMBER() OVER (ORDER BY ss.ss_net_paid DESC) AS rn
   FROM store_sales ss
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN promotion p
     ON ss.ss_promo_sk = p.p_promo_sk
   CROSS JOIN LATERAL (
       SELECT MAX(inv_quantity_on_hand) AS max_quantity
       FROM inventory inv
       WHERE inv.inv_item_sk = i.i_item_sk
   ) AS inv_max
   LEFT JOIN catalog_sales cs
     ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN web_returns wr
     ON wr.wr_item_sk = i.i_item_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2450800 AND 2451100
),
web_data AS (
   SELECT
     ws.ws_sold_date_sk AS date_sk,
     ws.ws_item_sk AS item_sk,
     i2.i_category,
     i2.i_brand,
     i2.i_product_name,
     ca2.ca_state,
     cd2.cd_gender,
     p2.p_promo_name,
     ws.ws_quantity AS quantity,
     ws.ws_net_paid AS net_paid,
     ws.ws_net_profit AS net_profit,
     inv_max2.max_quantity,
     cs2.cs_net_paid AS catalog_net_paid,
     wr2.wr_return_amt AS web_return_amt,
     ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_paid DESC) AS rn
   FROM web_sales ws
   JOIN item i2
     ON ws.ws_item_sk = i2.i_item_sk
   JOIN customer_address ca2
     ON ws.ws_bill_addr_sk = ca2.ca_address_sk
   JOIN customer_demographics cd2
     ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
   JOIN promotion p2
     ON ws.ws_promo_sk = p2.p_promo_sk
   JOIN web_site wsit
     ON ws.ws_web_site_sk = wsit.web_site_sk
   CROSS JOIN LATERAL (
       SELECT MAX(inv_quantity_on_hand) AS max_quantity
       FROM inventory inv
       WHERE inv.inv_item_sk = i2.i_item_sk
   ) AS inv_max2
   LEFT JOIN catalog_sales cs2
     ON cs2.cs_item_sk = i2.i_item_sk
   LEFT JOIN web_returns wr2
     ON wr2.wr_item_sk = i2.i_item_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2451100
)
SELECT DISTINCT
  combined.date_sk,
  combined.item_sk,
  combined.i_category,
  combined.i_brand,
  combined.i_product_name,
  combined.ca_state,
  combined.cd_gender,
  combined.p_promo_name,
  combined.quantity,
  combined.net_paid,
  combined.net_profit,
  combined.max_quantity,
  combined.catalog_net_paid,
  combined.web_return_amt,
  combined.rn,
  (SELECT MAX(cs_sub.cs_net_paid)
     FROM catalog_sales cs_sub
    WHERE cs_sub.cs_item_sk = combined.item_sk) AS max_catalog_net_paid
FROM (
   SELECT
     date_sk,
     item_sk,
     i_category,
     i_brand,
     i_product_name,
     ca_state,
     cd_gender,
     p_promo_name,
     quantity,
     net_paid,
     net_profit,
     max_quantity,
     catalog_net_paid,
     web_return_amt,
     rn
   FROM store_data
   UNION ALL
   SELECT
     date_sk,
     item_sk,
     i_category,
     i_brand,
     i_product_name,
     ca_state,
     cd_gender,
     p_promo_name,
     quantity,
     net_paid,
     net_profit,
     max_quantity,
     catalog_net_paid,
     web_return_amt,
     rn
   FROM web_data
) AS combined
WHERE (SELECT COUNT(*)
         FROM catalog_sales cs_cnt
        WHERE cs_cnt.cs_item_sk = combined.item_sk) > 5
ORDER BY combined.net_paid DESC
LIMIT 100
