WITH catalog_part AS (
   SELECT DISTINCT
          cr.cr_refunded_customer_sk AS customer_sk,
          cr.cr_net_loss           AS net_loss,
          w.w_city                AS location,
          'catalog'               AS source
   FROM catalog_returns cr
   JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
   JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE cr.cr_net_loss > 100.00
     AND w.w_state = 'CA'
),
store_part AS (
   SELECT DISTINCT
          sr.sr_customer_sk AS customer_sk,
          sr.sr_net_loss    AS net_loss,
          s.s_city          AS location,
          'store'           AS source
   FROM store_returns sr
   JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
   JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE sr.sr_net_loss > 100.00
     AND s.s_state = 'CA'
)
SELECT DISTINCT
       customer_sk,
       net_loss,
       location,
       source
FROM (
   SELECT * FROM catalog_part
   UNION ALL
   SELECT * FROM store_part
) combined
ORDER BY net_loss DESC
LIMIT 100
