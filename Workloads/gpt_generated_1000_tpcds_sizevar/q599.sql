WITH recent_dates AS (
   SELECT d_date_sk, d_year
   FROM date_dim
   WHERE d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
)
SELECT store_name,
       state,
       year,
       total_profit,
       total_refund,
       total_loss,
       order_count
FROM (
   /*--------------------  Store‑sales side --------------------*/
   SELECT
       s.s_store_name                         AS store_name,
       s.s_state                              AS state,
       d.d_year                               AS year,
       SUM(ss.ss_net_profit)                 AS total_profit,
       COALESCE(SUM(sr.sr_refunded_cash), 0)  AS total_refund,
       COALESCE(SUM(sr.sr_net_loss), 0)       AS total_loss,
       COUNT(DISTINCT ss.ss_ticket_number)    AS order_count
   FROM store_sales ss
   JOIN recent_dates rd                 ON ss.ss_sold_date_sk = rd.d_date_sk
   JOIN date_dim d                       ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t                       ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN store s                          ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p                      ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd        ON ss.ss_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN store_returns sr           
          ON sr.sr_ticket_number = ss.ss_ticket_number
         AND sr.sr_returned_date_sk = d.d_date_sk
   WHERE EXISTS (
         SELECT 1
         FROM (
               SELECT *
               FROM inventory TABLESAMPLE BERNOULLI (10)
              ) i
         WHERE i.inv_item_sk = ss.ss_item_sk
           AND i.inv_quantity_on_hand > 0
   )
   GROUP BY CUBE (s.s_store_name, s.s_state, d.d_year)

   UNION DISTINCT

   /*--------------------  Catalog‑sales side --------------------*/
   SELECT
       CAST(NULL AS varchar)                 AS store_name,
       CAST(NULL AS varchar)                 AS state,
       d2.d_year                             AS year,
       SUM(cs.cs_net_paid - cs.cs_ext_discount_amt) AS total_profit,
       COALESCE(SUM(cr.cr_refunded_cash), 0) AS total_refund,
       COALESCE(SUM(cr.cr_net_loss), 0)      AS total_loss,
       COUNT(DISTINCT cs.cs_order_number)   AS order_count
   FROM catalog_sales cs
   JOIN recent_dates rd2                 ON cs.cs_sold_date_sk = rd2.d_date_sk
   JOIN date_dim d2                       ON cs.cs_sold_date_sk = d2.d_date_sk
   JOIN time_dim t2                       ON cs.cs_sold_time_sk = t2.t_time_sk
   JOIN call_center cc                    ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp                   ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN promotion p2                      ON cs.cs_promo_sk = p2.p_promo_sk
   JOIN customer_demographics cd_bill    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN customer_demographics cd_ship    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
   LEFT JOIN catalog_returns cr          
          ON cr.cr_order_number = cs.cs_order_number
         AND cr.cr_returned_date_sk = d2.d_date_sk
   WHERE EXISTS (
         SELECT 1
         FROM (
               SELECT *
               FROM inventory TABLESAMPLE BERNOULLI (10)
              ) i2
         WHERE i2.inv_item_sk = cs.cs_item_sk
           AND i2.inv_quantity_on_hand > 0
   )
   GROUP BY CUBE (d2.d_year)
) AS combined
ORDER BY year DESC, total_profit DESC
LIMIT 100
