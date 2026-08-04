WITH promo_channels AS (
       SELECT p_promo_sk,
              ARRAY[p_channel_dmail, p_channel_email, p_channel_tv] AS channels
       FROM promotion
     ),
     scalar_max_cost AS (
       SELECT MAX(p_cost) AS max_cost FROM promotion
     )

SELECT
  store.s_store_name,
  item.i_category,
  SUM(ss_net_paid)                         AS total_store_sales,
  COUNT(DISTINCT ss_ticket_number)         AS order_cnt,
  COUNT(DISTINCT ch)                       AS channel_cnt
FROM store_sales
JOIN item
  ON store_sales.ss_item_sk = item.i_item_sk
JOIN customer
  ON store_sales.ss_customer_sk = customer.c_customer_sk
JOIN customer_demographics
  ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
JOIN customer_address
  ON store_sales.ss_addr_sk = customer_address.ca_address_sk
RIGHT JOIN store
  ON store_sales.ss_store_sk = store.s_store_sk
JOIN promotion
  ON store_sales.ss_promo_sk = promotion.p_promo_sk
JOIN promo_channels pc
  ON promotion.p_promo_sk = pc.p_promo_sk
CROSS JOIN UNNEST(pc.channels) AS t (ch)
LEFT JOIN inventory
  ON item.i_item_sk = inventory.inv_item_sk
LEFT JOIN warehouse
  ON inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
WHERE store.s_tax_percentage > (SELECT max_cost FROM scalar_max_cost)
GROUP BY GROUPING SETS (
  (store.s_store_name, item.i_category),
  (store.s_store_name),
  ()
)

UNION DISTINCT

SELECT
  web_site.web_name,
  item.i_category,
  SUM(ws_net_paid)                         AS total_web_sales,
  COUNT(DISTINCT ws_order_number)          AS order_cnt,
  COUNT(DISTINCT ch)                       AS channel_cnt
FROM web_sales
JOIN item
  ON web_sales.ws_item_sk = item.i_item_sk
JOIN customer
  ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
JOIN customer_demographics
  ON web_sales.ws_bill_cdemo_sk = customer_demographics.cd_demo_sk
JOIN customer_address
  ON web_sales.ws_bill_addr_sk = customer_address.ca_address_sk
JOIN web_site
  ON web_sales.ws_web_site_sk = web_site.web_site_sk
JOIN promotion
  ON web_sales.ws_promo_sk = promotion.p_promo_sk
JOIN promo_channels pc
  ON promotion.p_promo_sk = pc.p_promo_sk
CROSS JOIN UNNEST(pc.channels) AS t (ch)
LEFT JOIN warehouse
  ON web_sales.ws_warehouse_sk = warehouse.w_warehouse_sk
LEFT JOIN inventory
  ON item.i_item_sk = inventory.inv_item_sk
LEFT JOIN web_returns
  ON web_sales.ws_order_number = web_returns.wr_order_number
LEFT JOIN reason
  ON web_returns.wr_reason_sk = reason.r_reason_sk
WHERE web_site.web_tax_percentage > (SELECT max_cost FROM scalar_max_cost)
GROUP BY GROUPING SETS (
  (web_site.web_name, item.i_category),
  (web_site.web_name),
  ()
)

LIMIT 100
