WITH
  store_data AS (
    SELECT
      ss.ss_sold_date_sk      AS date_sk,
      d.d_date                AS d_date,
      ss.ss_sold_time_sk      AS time_sk,
      s.s_store_sk            AS store_sk,
      s.s_store_name          AS store_name,
      s.s_state               AS store_state,
      ss.ss_ext_sales_price   AS sales_amount,
      ss.ss_net_profit        AS net_profit,
      ss.ss_ticket_number     AS ticket_number,
      ss.ss_item_sk           AS item_sk,
      c.c_customer_sk         AS cust_sk,
      c.c_birth_country       AS birth_country,
      cd.cd_gender            AS gender,
      ca.ca_state             AS cust_state,
      p.p_promo_id            AS promo_id,
      p.p_channel_email       AS promo_email,
      sr.sr_return_amt        AS return_amt,
      rr.r_reason_desc        AS return_reason
    FROM store_sales ss
    JOIN date_dim d      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim td     ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s         ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca     ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p     ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason rr        ON sr.sr_reason_sk = rr.r_reason_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'CA'
      AND c.c_birth_country = 'United States'
      AND p.p_channel_email = 'Y'
  ),

  web_data AS (
    SELECT
      ws.ws_sold_date_sk      AS date_sk,
      d.d_date                AS d_date,
      ws.ws_sold_time_sk      AS time_sk,
      w.w_warehouse_sk        AS warehouse_sk,
      w.w_city                AS warehouse_city,
      w.w_state               AS warehouse_state,
      ws.ws_ext_sales_price   AS sales_amount,
      ws.ws_net_profit        AS net_profit,
      ws.ws_order_number      AS order_number,
      ws.ws_item_sk           AS item_sk,
      c.c_customer_sk         AS cust_sk,
      c.c_birth_country       AS birth_country,
      cd.cd_gender            AS gender,
      ca.ca_state             AS cust_state,
      p.p_promo_id            AS promo_id,
      p.p_channel_email       AS promo_email,
      wr.wr_return_amt        AS return_amt,
      rr.r_reason_desc        AS return_reason
    FROM web_sales ws
    JOIN date_dim d      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim td     ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN warehouse w     ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca     ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p     ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason rr        ON wr.wr_reason_sk = rr.r_reason_sk
    WHERE d.d_year = 2000
      AND w.w_state = 'CA'
      AND c.c_birth_country = 'United States'
      AND p.p_channel_email = 'Y'
  ),

  combined AS (
    SELECT
      'store'               AS channel,
      sd.date_sk,
      sd.d_date,
      sd.store_sk           AS location_sk,
      sd.store_name         AS location_name,
      sd.sales_amount,
      sd.net_profit,
      sd.return_amt
    FROM store_data sd
    UNION ALL
    SELECT
      'web'                 AS channel,
      wd.date_sk,
      wd.d_date,
      wd.warehouse_sk      AS location_sk,
      wd.warehouse_city    AS location_name,
      wd.sales_amount,
      wd.net_profit,
      wd.return_amt
    FROM web_data wd
  )
SELECT
  c.channel,
  c.location_name,
  DATE_TRUNC('year', c.d_date) AS sales_year,
  SUM(c.sales_amount)          AS total_sales,
  SUM(c.net_profit)            AS total_profit,
  SUM(COALESCE(c.return_amt, 0)) AS total_returns,
  RANK() OVER (PARTITION BY c.channel ORDER BY SUM(c.net_profit) DESC) AS profit_rank,
  cc.cc_name                   AS call_center_name,
  cp.cp_type                   AS catalog_page_type
FROM combined c
JOIN call_center cc ON cc.cc_closed_date_sk = c.date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk   = c.date_sk
WHERE cc.cc_country = 'United States'
  AND cp.cp_type = 'monthly'
GROUP BY
  c.channel,
  c.location_name,
  DATE_TRUNC('year', c.d_date),
  cc.cc_name,
  cp.cp_type
ORDER BY profit_rank
LIMIT 100
