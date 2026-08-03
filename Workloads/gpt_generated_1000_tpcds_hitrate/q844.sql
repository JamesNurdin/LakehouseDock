WITH
  sales_aggregated AS (
    SELECT
      d.d_date,
      s.s_store_sk,
      SUM(ss.ss_net_paid)                     AS total_net_paid,
      SUM(ss.ss_net_profit)                  AS total_net_profit,
      COUNT(*)                               AS sales_cnt,
      -- optional join‑level columns for later use
      w.w_warehouse_sk,
      p.p_promo_sk,
      cr.cr_return_quantity,
      ws.ws_quantity AS web_quantity
    FROM store_sales ss
    RIGHT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT  JOIN store s      ON ss.ss_store_sk = s.s_store_sk
    LEFT  JOIN item i       ON ss.ss_item_sk = i.i_item_sk
    LEFT  JOIN promotion p  ON ss.ss_promo_sk = p.p_promo_sk
    LEFT  JOIN time_dim t   ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT  JOIN customer c   ON ss.ss_customer_sk = c.c_customer_sk
    LEFT  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT  JOIN warehouse w   ON p.p_item_sk = i.i_item_sk            -- use promotion‑item link to reach warehouse via catalog_returns later
    LEFT  JOIN catalog_returns cr
           ON cr.cr_warehouse_sk = w.w_warehouse_sk
          AND cr.cr_returned_date_sk = d.d_date_sk
          AND cr.cr_item_sk = i.i_item_sk
    LEFT  JOIN web_sales ws
           ON ws.ws_sold_date_sk = d.d_date_sk
          AND ws.ws_item_sk = i.i_item_sk
          AND ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_brand_id = 5
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY d.d_date, s.s_store_sk, w.w_warehouse_sk, p.p_promo_sk, cr.cr_return_quantity, ws.ws_quantity
  ),
  returns_aggregated AS (
    SELECT
      d.d_date,
      i.i_item_sk,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*)               AS return_cnt
    FROM store_returns sr
    JOIN date_dim d       ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i           ON sr.sr_item_sk = i.i_item_sk
    JOIN store s          ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r         ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY d.d_date, i.i_item_sk
  ),
  missing_items AS (
    SELECT i.i_item_id
    FROM item i
    EXCEPT
    SELECT DISTINCT i2.i_item_id
    FROM store_sales ss
    JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
  ),
  joined_all AS (
    SELECT
      sa.d_date,
      sa.s_store_sk,
      sa.total_net_paid,
      sa.total_net_profit,
      ra.total_return_amt,
      ra.return_cnt,
      LAG(sa.total_net_paid) OVER (PARTITION BY sa.s_store_sk ORDER BY sa.d_date) AS prev_day_net_paid
    FROM sales_aggregated sa
    LEFT JOIN returns_aggregated ra
           ON sa.d_date = ra.d_date
  )
SELECT
  ja.d_date,
  ja.s_store_sk,
  ja.total_net_paid,
  ja.prev_day_net_paid,
  (ja.total_net_paid - COALESCE(ja.prev_day_net_paid, 0)) AS day_change,
  AVG(ja.total_net_paid) OVER (PARTITION BY ja.s_store_sk) AS avg_net_paid_per_store
FROM joined_all ja
WHERE ja.total_net_paid > 0
ORDER BY ja.s_store_sk, ja.d_date
