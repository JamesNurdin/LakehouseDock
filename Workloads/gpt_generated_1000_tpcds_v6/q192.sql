WITH ss_join AS (
   SELECT
      ss.ss_ticket_number AS store_ticket,
      ss.ss_item_sk,
      ss.ss_cdemo_sk,
      ss.ss_addr_sk,
      ss.ss_promo_sk,
      ss.ss_net_profit,
      td.t_hour,
      i.i_item_id,
      i.i_product_name,
      p.p_promo_name,
      cd.cd_gender,
      ca.ca_state,
      p.p_discount_active
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
),
cs_join AS (
   SELECT DISTINCT
      cs.cs_order_number AS catalog_order,
      cs.cs_item_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_addr_sk,
      cs.cs_promo_sk,
      cs.cs_net_profit,
      td.t_hour AS cs_hour,
      i.i_item_id,
      i.i_product_name,
      p.p_promo_name
   FROM catalog_sales cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
),
wr_join AS (
   SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_refunded_cdemo_sk,
      wr.wr_refunded_addr_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_net_loss,
      td.t_hour AS wr_hour,
      i.i_item_id,
      cd2.cd_gender AS wr_gender,
      ca2.ca_state AS wr_state
   FROM web_returns wr
   JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN customer_demographics cd2 ON wr.wr_refunded_cdemo_sk = cd2.cd_demo_sk
   JOIN customer_address ca2 ON wr.wr_refunded_addr_sk = ca2.ca_address_sk
)
SELECT
   i_item_id,
   t_hour,
   SUM(ss_net_profit) AS total_store_profit,
   SUM(cs_net_profit) AS total_catalog_profit,
   SUM(wr_net_loss)   AS total_return_loss,
   COUNT(DISTINCT store_ticket) AS distinct_store_tickets,
   CASE
      WHEN SUM(ss_net_profit) > 10000 THEN 'HIGH'
      ELSE 'NORMAL'
   END AS profit_category
FROM (
   SELECT
      i_item_id,
      t_hour,
      ss_net_profit,
      NULL AS cs_net_profit,
      NULL AS wr_net_loss,
      store_ticket
   FROM ss_join ss
   WHERE NOT EXISTS (
         SELECT 1 FROM promotion p2
         WHERE p2.p_promo_sk = ss.ss_promo_sk
           AND p2.p_discount_active = 'Y'
      )
   UNION ALL
   SELECT
      i_item_id,
      cs_hour AS t_hour,
      NULL,
      cs_net_profit,
      NULL,
      catalog_order
   FROM cs_join cs
   UNION ALL
   SELECT
      i_item_id,
      wr_hour AS t_hour,
      NULL,
      NULL,
      wr_net_loss,
      NULL
   FROM wr_join wr
) agg
GROUP BY ROLLUP (i_item_id, t_hour)
ORDER BY i_item_id, t_hour
LIMIT 100
