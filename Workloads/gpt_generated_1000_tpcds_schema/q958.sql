WITH base_sales AS (
   SELECT *
   FROM store_sales
   TABLESAMPLE BERNOULLI (10)
)
SELECT *
FROM (
   SELECT *
   FROM (
      SELECT
         s.s_store_name,
         d.d_year,
         d.d_month_seq      AS month,
         ss.ss_net_paid,
         ss.ss_net_profit,
         ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss.ss_net_paid DESC) AS sales_rank,
         lf.loss_flag
      FROM base_sales ss
      JOIN date_dim d            ON ss.ss_sold_date_sk = d.d_date_sk
      JOIN time_dim t            ON ss.ss_sold_time_sk = t.t_time_sk
      JOIN store s               ON ss.ss_store_sk = s.s_store_sk
      JOIN item i                ON ss.ss_item_sk = i.i_item_sk
      JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
      JOIN customer c            ON ss.ss_customer_sk = c.c_customer_sk
      JOIN customer_address ca   ON ss.ss_addr_sk = ca.ca_address_sk
      JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
      LEFT JOIN LATERAL (
         SELECT CASE WHEN ss.ss_net_profit < 0 THEN 1 ELSE 0 END AS loss_flag
      ) lf ON TRUE
      WHERE d.d_year = 2001
        AND s.s_state = 'TN'
        AND i.i_brand_id IN (1004002, 8007005)

      UNION DISTINCT

      SELECT
         s.s_store_name,
         d.d_year,
         d.d_month_seq      AS month,
         sr.sr_refunded_cash AS ss_net_paid,
         sr.sr_net_loss      AS ss_net_profit,
         ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY sr.sr_refunded_cash DESC) AS sales_rank,
         lf.loss_flag
      FROM store_returns sr
      JOIN date_dim d            ON sr.sr_returned_date_sk = d.d_date_sk
      JOIN time_dim t            ON sr.sr_return_time_sk = t.t_time_sk
      JOIN store s               ON sr.sr_store_sk = s.s_store_sk
      JOIN item i                ON sr.sr_item_sk = i.i_item_sk
      JOIN customer c            ON sr.sr_customer_sk = c.c_customer_sk
      JOIN customer_address ca   ON sr.sr_addr_sk = ca.ca_address_sk
      JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
      LEFT JOIN LATERAL (
         SELECT CASE WHEN sr.sr_net_loss < 0 THEN 1 ELSE 0 END AS loss_flag
      ) lf ON TRUE
      WHERE d.d_year = 2001
        AND s.s_state = 'TN'
        AND i.i_brand_id IN (1004002, 8007005)
   ) AS unioned
   EXCEPT
   SELECT
      excl.s_store_name,
      excl.d_year,
      excl.month,
      excl.ss_net_paid,
      excl.ss_net_profit,
      excl.sales_rank,
      excl.loss_flag
   FROM (
      SELECT
         s.s_store_name,
         d.d_year,
         d.d_month_seq      AS month,
         CAST(0 AS decimal(7,2)) AS ss_net_paid,
         CAST(0 AS decimal(7,2)) AS ss_net_profit,
         0                     AS sales_rank,
         0                     AS loss_flag
      FROM call_center cc
      JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
      JOIN store s    ON s.s_closed_date_sk = d.d_date_sk
      WHERE d.d_year = 2001

      UNION ALL

      SELECT
         s.s_store_name,
         d.d_year,
         d.d_month_seq      AS month,
         CAST(0 AS decimal(7,2)) AS ss_net_paid,
         CAST(0 AS decimal(7,2)) AS ss_net_profit,
         0                     AS sales_rank,
         0                     AS loss_flag
      FROM web_site ws
      JOIN date_dim d ON ws.web_close_date_sk = d.d_date_sk
      JOIN store s    ON s.s_closed_date_sk = d.d_date_sk
      WHERE d.d_year = 2001
   ) AS excl
) AS final_result
ORDER BY ss_net_paid DESC, sales_rank ASC
LIMIT 100
