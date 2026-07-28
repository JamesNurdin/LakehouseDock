WITH base AS (
   SELECT
       s.s_store_sk,
       s.s_store_name,
       d.d_year,
       cs.cs_net_profit AS cs_net_profit,
       cr.cr_net_loss AS cr_net_loss,
       ss.ss_net_profit AS ss_net_profit,
       sr.sr_net_loss AS sr_net_loss,
       p.p_promo_id,
       cp.cp_department,
       sm.sm_type,
       hd.hd_buy_potential,
       r.r_reason_desc
   FROM catalog_sales cs
   JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
   JOIN catalog_returns cr       ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
   JOIN reason r                 ON cr.cr_reason_sk = r.r_reason_sk
   JOIN store_sales ss           ON ss.ss_sold_date_sk = d.d_date_sk
                                 AND ss.ss_sold_time_sk = t.t_time_sk
   JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
   JOIN store_returns sr         ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_item_sk = ss.ss_item_sk
   JOIN reason r2                ON sr.sr_reason_sk = r2.r_reason_sk
   JOIN date_dim dr              ON sr.sr_returned_date_sk = dr.d_date_sk
   WHERE d.d_year = 2001
     AND s.s_country = 'United States'
     AND c.c_salutation = 'Mr.'
     AND hd.hd_buy_potential = 'High'
     AND EXISTS (
         SELECT 1 FROM promotion p2
         WHERE p2.p_promo_sk = cs.cs_promo_sk
           AND p2.p_start_date_sk BETWEEN 2450000 AND 2452000
     )
),
store_year_agg AS (
   SELECT
       s_store_sk,
       s_store_name,
       d_year,
       SUM(cs_net_profit) AS sum_cs_profit,
       SUM(cr_net_loss) AS sum_cr_loss,
       SUM(ss_net_profit) AS sum_ss_profit,
       SUM(sr_net_loss) AS sum_sr_loss,
       (SUM(cs_net_profit) + SUM(ss_net_profit) - SUM(cr_net_loss) - SUM(sr_net_loss)) AS total_profit
   FROM base
   GROUP BY s_store_sk, s_store_name, d_year
)
SELECT
    s_store_sk,
    s_store_name,
    d_year,
    total_profit,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    (SELECT COUNT(*) FROM catalog_returns WHERE cr_return_quantity > 0) AS total_return_rows
FROM store_year_agg
WHERE total_profit > (
    SELECT AVG(total_profit) FROM store_year_agg
)
ORDER BY total_profit DESC
LIMIT 100
