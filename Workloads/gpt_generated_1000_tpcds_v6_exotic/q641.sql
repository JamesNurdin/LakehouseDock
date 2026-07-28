WITH
  catalog_data AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_order_number,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cp.cp_department,
      p.p_promo_name,
      cr.cr_return_amount,
      cr.cr_net_loss,
      r.r_reason_desc,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      hd.hd_buy_potential
    FROM catalog_sales cs
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p                  ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t                   ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib               ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr     ON cr.cr_order_number = cs.cs_order_number
                                      AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r               ON cr.cr_reason_sk = r.r_reason_sk
    WHERE t.t_second = 0
  ),
  store_data AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_ticket_number,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      sr.sr_return_amt,
      sr.sr_net_loss,
      r2.r_reason_desc   AS store_return_reason,
      ib2.ib_lower_bound,
      ib2.ib_upper_bound,
      hd2.hd_buy_potential
    FROM store_sales ss
    JOIN time_dim t2                 ON ss.ss_sold_time_sk = t2.t_time_sk
    JOIN household_demographics hd2  ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2             ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    JOIN promotion p2                ON ss.ss_promo_sk = p2.p_promo_sk
    LEFT JOIN store_returns sr      ON sr.sr_ticket_number = ss.ss_ticket_number
                                      AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r2             ON sr.sr_reason_sk = r2.r_reason_sk
    WHERE t2.t_second = 0
  ),
  web_data AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      wr.wr_return_amt,
      wr.wr_net_loss,
      r3.r_reason_desc   AS web_return_reason,
      ib3.ib_lower_bound,
      ib3.ib_upper_bound,
      hd3.hd_buy_potential,
      ws.ws_web_site_sk
    FROM web_sales ws
    JOIN time_dim t3                 ON ws.ws_sold_time_sk = t3.t_time_sk
    JOIN household_demographics hd3  ON ws.ws_bill_hdemo_sk = hd3.hd_demo_sk
    JOIN income_band ib3             ON hd3.hd_income_band_sk = ib3.ib_income_band_sk
    JOIN promotion p3                ON ws.ws_promo_sk = p3.p_promo_sk
    JOIN web_site wsit               ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN web_returns wr        ON wr.wr_order_number = ws.ws_order_number
                                      AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r3             ON wr.wr_reason_sk = r3.r_reason_sk
    WHERE t3.t_second = 0
  )
SELECT
  ib_lower_bound,
  ib_upper_bound,
  hd_buy_potential,
  SUM(catalog_ext_sales_price)          AS total_catalog_sales,
  SUM(catalog_net_profit)               AS total_catalog_profit,
  SUM(COALESCE(catalog_return_amount, 0)) AS total_catalog_return_amount,
  SUM(COALESCE(catalog_return_loss,   0)) AS total_catalog_return_loss,
  SUM(store_ext_sales_price)            AS total_store_sales,
  SUM(store_net_profit)                 AS total_store_profit,
  SUM(COALESCE(store_return_amt, 0))    AS total_store_return_amount,
  SUM(COALESCE(store_return_loss, 0))   AS total_store_return_loss,
  SUM(web_ext_sales_price)              AS total_web_sales,
  SUM(web_net_profit)                   AS total_web_profit,
  SUM(COALESCE(web_return_amt, 0))      AS total_web_return_amount,
  SUM(COALESCE(web_return_loss, 0))     AS total_web_return_loss
FROM (
  SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    cs_ext_sales_price      AS catalog_ext_sales_price,
    cs_net_profit           AS catalog_net_profit,
    cr_return_amount        AS catalog_return_amount,
    cr_net_loss             AS catalog_return_loss,
    CAST(NULL AS decimal(7,2)) AS store_ext_sales_price,
    CAST(NULL AS decimal(7,2)) AS store_net_profit,
    CAST(NULL AS decimal(7,2)) AS store_return_amt,
    CAST(NULL AS decimal(7,2)) AS store_return_loss,
    CAST(NULL AS decimal(7,2)) AS web_ext_sales_price,
    CAST(NULL AS decimal(7,2)) AS web_net_profit,
    CAST(NULL AS decimal(7,2)) AS web_return_amt,
    CAST(NULL AS decimal(7,2)) AS web_return_loss
  FROM catalog_data
  UNION ALL
  SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    CAST(NULL AS decimal(7,2)) AS catalog_ext_sales_price,
    CAST(NULL AS decimal(7,2)) AS catalog_net_profit,
    CAST(NULL AS decimal(7,2)) AS catalog_return_amount,
    CAST(NULL AS decimal(7,2)) AS catalog_return_loss,
    ss_ext_sales_price,
    ss_net_profit,
    sr_return_amt,
    sr_net_loss,
    CAST(NULL AS decimal(7,2)) AS web_ext_sales_price,
    CAST(NULL AS decimal(7,2)) AS web_net_profit,
    CAST(NULL AS decimal(7,2)) AS web_return_amt,
    CAST(NULL AS decimal(7,2)) AS web_return_loss
  FROM store_data
  UNION ALL
  SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    CAST(NULL AS decimal(7,2)) AS catalog_ext_sales_price,
    CAST(NULL AS decimal(7,2)) AS catalog_net_profit,
    CAST(NULL AS decimal(7,2)) AS catalog_return_amount,
    CAST(NULL AS decimal(7,2)) AS catalog_return_loss,
    CAST(NULL AS decimal(7,2)) AS store_ext_sales_price,
    CAST(NULL AS decimal(7,2)) AS store_net_profit,
    CAST(NULL AS decimal(7,2)) AS store_return_amt,
    CAST(NULL AS decimal(7,2)) AS store_return_loss,
    ws_ext_sales_price,
    ws_net_profit,
    wr_return_amt,
    wr_net_loss
  FROM web_data
) AS agg
GROUP BY
  ib_lower_bound,
  ib_upper_bound,
  hd_buy_potential
ORDER BY
  ib_lower_bound ASC,
  total_catalog_sales DESC
LIMIT 100
