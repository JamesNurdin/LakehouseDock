WITH
  store_part AS (
    SELECT
      p.p_promo_name AS promo_name,
      hd.hd_buy_potential AS buy_potential,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(*) AS transaction_count
    FROM tpcds.store_sales ss
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_market_manager = 'David Smith'
      AND s.s_rec_end_date >= DATE '2000-01-01'
    GROUP BY p.p_promo_name, hd.hd_buy_potential
  ),
  web_part AS (
    SELECT
      p.p_promo_name AS promo_name,
      hd.hd_buy_potential AS buy_potential,
      SUM(ws.ws_net_paid) AS total_net_paid,
      COUNT(*) AS transaction_count
    FROM tpcds.web_sales ws
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_response_target = 1
      AND ws.ws_sold_date_sk BETWEEN 2450185 AND 2450357
    GROUP BY p.p_promo_name, hd.hd_buy_potential
  )
SELECT
  promo_name,
  buy_potential,
  total_net_paid,
  transaction_count
FROM store_part
UNION ALL
SELECT
  promo_name,
  buy_potential,
  total_net_paid,
  transaction_count
FROM web_part
ORDER BY total_net_paid DESC
LIMIT 100
