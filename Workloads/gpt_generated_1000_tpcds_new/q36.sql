WITH base AS (
   SELECT
      ss.ss_ticket_number,
      ss.ss_store_sk,
      s.s_store_name,
      ca.ca_state,
      p.p_promo_name,
      r.r_reason_desc,
      ss.ss_net_profit,
      ss.ss_ext_sales_price,
      sr.sr_return_amt,
      cs.cs_net_paid,
      cs.cs_quantity,
      cp.cp_department,
      wp.wp_url,
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      td_ss.t_hour AS sale_hour,
      td_sr.t_hour AS return_hour,
      td_cs.t_hour AS catalog_hour,
      td_wr.t_hour AS web_return_hour
   FROM store_sales ss
   JOIN time_dim td_ss          ON ss.ss_sold_time_sk   = td_ss.t_time_sk
   JOIN store s                 ON ss.ss_store_sk       = s.s_store_sk
   JOIN customer c              ON ss.ss_customer_sk    = c.c_customer_sk
   JOIN customer_address ca    ON ss.ss_addr_sk        = ca.ca_address_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk     = cd.cd_demo_sk
   JOIN promotion p             ON ss.ss_promo_sk       = p.p_promo_sk
   LEFT JOIN store_returns sr   ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_store_sk      = ss.ss_store_sk
   LEFT JOIN reason r           ON sr.sr_reason_sk      = r.r_reason_sk
   LEFT JOIN time_dim td_sr     ON sr.sr_return_time_sk = td_sr.t_time_sk
   LEFT JOIN catalog_sales cs   ON cs.cs_bill_customer_sk = c.c_customer_sk
                               AND cs.cs_bill_cdemo_sk   = cd.cd_demo_sk
                               AND cs.cs_bill_addr_sk    = ca.ca_address_sk
   LEFT JOIN time_dim td_cs     ON cs.cs_sold_time_sk      = td_cs.t_time_sk
   LEFT JOIN catalog_page cp    ON cs.cs_catalog_page_sk   = cp.cp_catalog_page_sk
   LEFT JOIN promotion p2        ON cs.cs_promo_sk          = p2.p_promo_sk
   LEFT JOIN web_returns wr     ON wr.wr_refunded_customer_sk = c.c_customer_sk
   LEFT JOIN time_dim td_wr     ON wr.wr_returned_time_sk      = td_wr.t_time_sk
   LEFT JOIN web_page wp        ON wr.wr_web_page_sk          = wp.wp_web_page_sk
   LEFT JOIN reason r2          ON wr.wr_reason_sk            = r2.r_reason_sk
   WHERE td_ss.t_hour BETWEEN 9 AND 18
)
SELECT
   b.s_store_name,
   b.ca_state,
   b.p_promo_name,
   COUNT(DISTINCT b.c_customer_sk)                         AS unique_customers,
   SUM(b.ss_net_profit)                                    AS total_net_profit,
   SUM(COALESCE(b.sr_return_amt, 0))                       AS total_return_amount,
   SUM(COALESCE(b.cs_net_paid, 0))                         AS total_catalog_net_paid,
   ROW_NUMBER() OVER (PARTITION BY b.s_store_name ORDER BY SUM(b.ss_net_profit) DESC) AS rn_store_profit
FROM base b
WHERE NOT EXISTS (
   SELECT 1 FROM web_returns wrx
   WHERE wrx.wr_refunded_customer_sk = b.c_customer_sk
)
GROUP BY
   b.s_store_name,
   b.ca_state,
   b.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
