WITH sales_data AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_sold_date_sk,
       ss.ss_item_sk,
       ss.ss_store_sk,
       ss.ss_customer_sk,
       ss.ss_quantity,
       ss.ss_ext_sales_price,
       ss.ss_net_profit,
       d_sales.d_year,
       i.i_item_id,
       i.i_product_name,
       i.i_category,
       c.c_first_name,
       c.c_last_name,
       cd.cd_gender,
       ca.ca_state,
       s.s_store_name,
       s.s_state,
       inv.inv_quantity_on_hand,
       cc.cc_name AS call_center_name,
       cp.cp_catalog_number,
       wp.wp_url
   FROM store_sales ss
   JOIN date_dim d_sales
     ON ss.ss_sold_date_sk = d_sales.d_date_sk
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN inventory inv
     ON inv.inv_item_sk = ss.ss_item_sk
    AND inv.inv_date_sk = d_sales.d_date_sk
   LEFT JOIN call_center cc
     ON cc.cc_open_date_sk = d_sales.d_date_sk
   LEFT JOIN catalog_page cp
     ON cp.cp_start_date_sk = d_sales.d_date_sk
   LEFT JOIN web_page wp
     ON wp.wp_creation_date_sk = d_sales.d_date_sk
    AND wp.wp_customer_sk = c.c_customer_sk
)
SELECT
    d_return.d_year AS return_year,
    sd.s_store_name,
    sd.i_category,
    CASE WHEN sd.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region_group,
    COUNT(DISTINCT sd.ss_ticket_number) AS orders,
    SUM(sd.ss_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    SUM(sd.ss_net_profit) - SUM(sr.sr_return_amt) AS net_profit_after_returns,
    AVG(sd.inv_quantity_on_hand) AS avg_inventory_on_hand,
    (SELECT AVG(i_current_price) FROM item) AS avg_item_price,
    MAX(sr.sr_returned_date_sk) FILTER (WHERE sr.sr_return_amt > 0) AS latest_return_date_sk
FROM sales_data sd
JOIN store_returns sr
  ON sr.sr_ticket_number = sd.ss_ticket_number
 AND sr.sr_item_sk = sd.ss_item_sk
 AND sr.sr_store_sk = sd.ss_store_sk
 AND sr.sr_customer_sk = sd.ss_customer_sk
JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = sd.ss_store_sk
      AND sr2.sr_returned_date_sk = d_return.d_date_sk
)
GROUP BY
    d_return.d_year,
    sd.s_store_name,
    sd.i_category,
    CASE WHEN sd.s_state = 'CA' THEN 'West' ELSE 'Other' END
ORDER BY total_sales DESC
LIMIT 100
