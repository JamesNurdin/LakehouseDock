WITH sales_agg AS (
   SELECT
      c.c_customer_sk,
      c.c_customer_id,
      SUM(cs.cs_net_profit)                         AS catalog_net_profit,
      SUM(ws.ws_net_profit)                         AS web_net_profit,
      SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_sales,
      CASE
         WHEN SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) > 10000 THEN 'High'
         WHEN SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) > 5000  THEN 'Medium'
         ELSE 'Low'
      END                                          AS profit_category,
      COUNT(DISTINCT sr.sr_ticket_number)           AS return_ticket_cnt
   FROM
      catalog_sales cs
      JOIN catalog_page cp            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN promotion p                ON cs.cs_promo_sk = p.p_promo_sk
      JOIN ship_mode sm               ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN warehouse w                ON cs.cs_warehouse_sk = w.w_warehouse_sk
      JOIN time_dim td                ON cs.cs_sold_time_sk = td.t_time_sk
      JOIN customer c                 ON cs.cs_bill_customer_sk = c.c_customer_sk
      JOIN customer_address ca        ON cs.cs_bill_addr_sk = ca.ca_address_sk
      JOIN customer_demographics cd   ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      LEFT JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
      LEFT JOIN web_sales ws          ON ws.ws_sold_time_sk = td.t_time_sk
                                         AND ws.ws_bill_customer_sk = c.c_customer_sk
      LEFT JOIN web_site wsite         ON ws.ws_web_site_sk = wsite.web_site_sk
      LEFT JOIN store_returns sr      ON sr.sr_return_time_sk = td.t_time_sk
                                         AND sr.sr_customer_sk = c.c_customer_sk
      LEFT JOIN reason r              ON sr.sr_reason_sk = r.r_reason_sk
   WHERE
      p.p_discount_active = 'Y'
      AND ib.ib_lower_bound >= 50000
      AND hd.hd_vehicle_count > 0
      AND td.t_hour BETWEEN 8 AND 20
      AND c.c_preferred_cust_flag = 'Y'
   GROUP BY
      c.c_customer_sk,
      c.c_customer_id
)
SELECT
   sa.c_customer_id,
   sa.catalog_net_profit,
   sa.web_net_profit,
   sa.total_sales,
   sa.profit_category,
   (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_customer_sk = sa.c_customer_sk) AS total_return_tickets,
   RANK() OVER (ORDER BY (sa.catalog_net_profit + sa.web_net_profit) DESC) AS profit_rank
FROM
   sales_agg sa
WHERE NOT EXISTS (
   SELECT 1
   FROM store_returns sr3
   WHERE sr3.sr_customer_sk = sa.c_customer_sk
     AND sr3.sr_return_amt > 1000
)
ORDER BY profit_rank
LIMIT 100
