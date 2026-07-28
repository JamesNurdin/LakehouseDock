WITH
  store_aggs AS (
    SELECT
      'store' AS channel,
      d.d_year AS d_year,
      hd.hd_buy_potential AS hd_buy_potential,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND ss.ss_net_paid > 0
      AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
          AND sr.sr_return_quantity > 0
      )
    GROUP BY GROUPING SETS (
      (d.d_year, hd.hd_buy_potential),
      (d.d_year),
      ()
    )
  ),
  web_aggs AS (
    SELECT
      'web' AS channel,
      d.d_year AS d_year,
      hd.hd_buy_potential AS hd_buy_potential,
      SUM(ws.ws_net_paid) AS total_net_paid,
      COUNT(*) AS txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND ws.ws_net_paid > 0
      AND ws.ws_web_site_sk IN (
        SELECT ws2.web_site_sk
        FROM web_site ws2
        JOIN date_dim d2 ON ws2.web_open_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2003
      )
    GROUP BY GROUPING SETS (
      (d.d_year, hd.hd_buy_potential),
      (d.d_year),
      ()
    )
  ),
  combined AS (
    SELECT * FROM store_aggs
    UNION ALL
    SELECT * FROM web_aggs
  )
SELECT
  channel,
  d_year,
  hd_buy_potential,
  total_net_paid,
  txn_cnt,
  (SELECT AVG(total_net_paid) FROM combined) AS avg_total_net_paid_all
FROM combined
ORDER BY
  channel,
  d_year,
  hd_buy_potential
