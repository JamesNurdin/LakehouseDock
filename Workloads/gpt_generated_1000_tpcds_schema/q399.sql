WITH sales_data AS (
   SELECT
     ss.ss_ticket_number,
     ss.ss_sold_date_sk,
     d.d_year,
     i.i_item_id,
     i.i_category,
     i.i_brand,
     i.i_current_price,
     ss.ss_quantity,
     ss.ss_net_paid,
     ss.ss_net_profit,
     p.p_promo_name,
     p.p_purpose,
     hd.hd_vehicle_count,
     cd.cd_gender,
     ca.ca_state,
     (
       SELECT SUM(sr2.sr_return_amt_inc_tax)
       FROM store_returns sr2
       WHERE sr2.sr_ticket_number = ss.ss_ticket_number
     ) AS ticket_return_amt,
     ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ss.ss_net_profit DESC) AS profit_rank
   FROM store_sales ss
   JOIN date_dim d               ON ss.ss_sold_date_sk   = d.d_date_sk
   JOIN item i                   ON ss.ss_item_sk       = i.i_item_sk
   JOIN promotion p              ON ss.ss_promo_sk      = p.p_promo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk      = hd.hd_demo_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk      = cd.cd_demo_sk
   JOIN customer_address ca      ON ss.ss_addr_sk       = ca.ca_address_sk
   WHERE d.d_year = 2001
     AND i.i_current_price > 50
     AND hd.hd_vehicle_count >= 1
     AND p.p_purpose = 'Unknown'
     AND EXISTS (
           SELECT 1
           FROM web_returns wr
           WHERE wr.wr_item_sk = ss.ss_item_sk
             AND wr.wr_return_amt > 0
         )
),
catalog_data AS (
   SELECT
     cs.cs_order_number,
     cs.cs_sold_date_sk,
     d2.d_year               AS year,
     i2.i_item_id,
     cp.cp_catalog_number,
     cc.cc_name,
     cs.cs_quantity,
     cs.cs_net_paid,
     cs.cs_net_profit,
     p2.p_promo_name,
     p2.p_purpose,
     wr.wr_return_amt,
     wp.wp_url,
     ROW_NUMBER() OVER (PARTITION BY i2.i_item_id ORDER BY cs.cs_net_profit DESC) AS profit_rank
   FROM catalog_sales cs
   JOIN date_dim d2           ON cs.cs_sold_date_sk   = d2.d_date_sk
   JOIN item i2               ON cs.cs_item_sk       = i2.i_item_sk
   JOIN promotion p2          ON cs.cs_promo_sk      = p2.p_promo_sk
   JOIN call_center cc        ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN web_returns wr        ON wr.wr_item_sk      = cs.cs_item_sk
   JOIN web_page wp           ON wr.wr_web_page_sk  = wp.wp_web_page_sk
   WHERE d2.d_year = 2001
     AND p2.p_discount_active = 'Y'
     AND cp.cp_type = 'P'
)
SELECT *
FROM (
   SELECT
     i_item_id,
     d_year               AS year,
     ss_net_profit        AS net_profit,
     'store'              AS source,
     profit_rank
   FROM sales_data
   WHERE profit_rank <= 5

   UNION DISTINCT

   SELECT
     i_item_id,
     year,
     cs_net_profit        AS net_profit,
     'catalog'            AS source,
     profit_rank
   FROM catalog_data
   WHERE profit_rank <= 5
) AS combined
EXCEPT
SELECT
   i_item_id,
   d_year,
   ss_net_profit,
   'store',
   profit_rank
FROM sales_data
WHERE profit_rank = 1
  AND ss_net_profit < 0
ORDER BY net_profit DESC
LIMIT 100
