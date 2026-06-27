WITH
  store_profit AS (
    SELECT
      ib.ib_lower_bound AS lower_bound,
      ib.ib_upper_bound AS upper_bound,
      hd.hd_buy_potential,
      SUM(ss.ss_net_profit) AS net_profit,
      COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
  ),
  store_loss AS (
    SELECT
      ib.ib_lower_bound AS lower_bound,
      ib.ib_upper_bound AS upper_bound,
      hd.hd_buy_potential,
      SUM(sr.sr_net_loss) AS net_loss,
      COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
  ),
  catalog_profit AS (
    SELECT
      ib.ib_lower_bound AS lower_bound,
      ib.ib_upper_bound AS upper_bound,
      hd.hd_buy_potential,
      SUM(cs.cs_net_profit) AS net_profit,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
  ),
  catalog_loss AS (
    SELECT
      ib.ib_lower_bound AS lower_bound,
      ib.ib_upper_bound AS upper_bound,
      hd.hd_buy_potential,
      SUM(cr.cr_net_loss) AS net_loss,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
  ),
  web_profit AS (
    SELECT
      ib.ib_lower_bound AS lower_bound,
      ib.ib_upper_bound AS upper_bound,
      hd.hd_buy_potential,
      SUM(ws.ws_net_profit) AS net_profit,
      COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
  ),
  web_loss AS (
    SELECT
      ib.ib_lower_bound AS lower_bound,
      ib.ib_upper_bound AS upper_bound,
      hd.hd_buy_potential,
      SUM(wr.wr_net_loss) AS net_loss,
      COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
  ),
  combined AS (
    SELECT
      'store' AS channel,
      sp.lower_bound,
      sp.upper_bound,
      sp.hd_buy_potential,
      sp.net_profit,
      sl.net_loss,
      sp.sales_cnt,
      sl.return_cnt
    FROM store_profit sp
    LEFT JOIN store_loss sl
      ON sp.lower_bound = sl.lower_bound
     AND sp.upper_bound = sl.upper_bound
     AND sp.hd_buy_potential = sl.hd_buy_potential

    UNION ALL

    SELECT
      'catalog' AS channel,
      cp.lower_bound,
      cp.upper_bound,
      cp.hd_buy_potential,
      cp.net_profit,
      cl.net_loss,
      cp.sales_cnt,
      cl.return_cnt
    FROM catalog_profit cp
    LEFT JOIN catalog_loss cl
      ON cp.lower_bound = cl.lower_bound
     AND cp.upper_bound = cl.upper_bound
     AND cp.hd_buy_potential = cl.hd_buy_potential

    UNION ALL

    SELECT
      'web' AS channel,
      wp.lower_bound,
      wp.upper_bound,
      wp.hd_buy_potential,
      wp.net_profit,
      wl.net_loss,
      wp.sales_cnt,
      wl.return_cnt
    FROM web_profit wp
    LEFT JOIN web_loss wl
      ON wp.lower_bound = wl.lower_bound
     AND wp.upper_bound = wl.upper_bound
     AND wp.hd_buy_potential = wl.hd_buy_potential
  )
SELECT
  channel,
  lower_bound,
  upper_bound,
  hd_buy_potential,
  net_profit,
  net_loss,
  sales_cnt,
  return_cnt,
  (net_profit - COALESCE(net_loss, 0)) AS net_contribution
FROM combined
ORDER BY channel, lower_bound, upper_bound
