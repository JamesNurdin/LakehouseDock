WITH
  all_sales AS (
    SELECT
      cs_sold_date_sk AS date_sk,
      cs_call_center_sk AS call_center_sk,
      CAST(NULL AS integer) AS store_sk,
      CAST(NULL AS integer) AS web_page_sk,
      cs_net_paid AS net_paid,
      cs_net_profit AS net_profit,
      cs_ext_sales_price AS ext_sales_price,
      'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT
      ss_sold_date_sk AS date_sk,
      CAST(NULL AS integer) AS call_center_sk,
      ss_store_sk AS store_sk,
      CAST(NULL AS integer) AS web_page_sk,
      ss_net_paid AS net_paid,
      ss_net_profit AS net_profit,
      ss_ext_sales_price AS ext_sales_price,
      'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
      ws_sold_date_sk AS date_sk,
      CAST(NULL AS integer) AS call_center_sk,
      CAST(NULL AS integer) AS store_sk,
      ws_web_page_sk AS web_page_sk,
      ws_net_paid AS net_paid,
      ws_net_profit AS net_profit,
      ws_ext_sales_price AS ext_sales_price,
      'web' AS channel
    FROM web_sales
  ),
  all_returns AS (
    SELECT
      cr_returned_date_sk AS date_sk,
      cr_call_center_sk AS call_center_sk,
      CAST(NULL AS integer) AS store_sk,
      CAST(NULL AS integer) AS web_page_sk,
      cr_refunded_cash AS refund_amount,
      cr_net_loss AS net_loss,
      cr_return_amount AS return_amount,
      'catalog' AS channel
    FROM catalog_returns
    UNION ALL
    SELECT
      sr_returned_date_sk AS date_sk,
      CAST(NULL AS integer) AS call_center_sk,
      sr_store_sk AS store_sk,
      CAST(NULL AS integer) AS web_page_sk,
      sr_refunded_cash AS refund_amount,
      sr_net_loss AS net_loss,
      sr_return_amt AS return_amount,
      'store' AS channel
    FROM store_returns
    UNION ALL
    SELECT
      wr_returned_date_sk AS date_sk,
      CAST(NULL AS integer) AS call_center_sk,
      CAST(NULL AS integer) AS store_sk,
      wr_web_page_sk AS web_page_sk,
      wr_refunded_cash AS refund_amount,
      wr_net_loss AS net_loss,
      wr_return_amt AS return_amount,
      'web' AS channel
    FROM web_returns
  ),
  daily_sales AS (
    SELECT
      d.d_date_sk,
      d.d_date,
      s.channel,
      COALESCE(s.call_center_sk, -1) AS call_center_sk,
      COALESCE(s.store_sk, -1) AS store_sk,
      COALESCE(s.web_page_sk, -1) AS web_page_sk,
      SUM(s.net_paid) AS total_net_paid,
      SUM(s.net_profit) AS total_net_profit,
      SUM(s.ext_sales_price) AS total_sales_amount
    FROM all_sales s
    JOIN date_dim d ON d.d_date_sk = s.date_sk
    GROUP BY
      d.d_date_sk,
      d.d_date,
      s.channel,
      COALESCE(s.call_center_sk, -1),
      COALESCE(s.store_sk, -1),
      COALESCE(s.web_page_sk, -1)
  ),
  daily_returns AS (
    SELECT
      d.d_date_sk,
      d.d_date,
      r.channel,
      COALESCE(r.call_center_sk, -1) AS call_center_sk,
      COALESCE(r.store_sk, -1) AS store_sk,
      COALESCE(r.web_page_sk, -1) AS web_page_sk,
      SUM(r.refund_amount) AS total_refund_amount,
      SUM(r.net_loss) AS total_net_loss,
      SUM(r.return_amount) AS total_return_amount
    FROM all_returns r
    JOIN date_dim d ON d.d_date_sk = r.date_sk
    GROUP BY
      d.d_date_sk,
      d.d_date,
      r.channel,
      COALESCE(r.call_center_sk, -1),
      COALESCE(r.store_sk, -1),
      COALESCE(r.web_page_sk, -1)
  ),
  combined AS (
    SELECT
      ds.d_date_sk,
      ds.d_date,
      ds.channel,
      ds.call_center_sk,
      ds.store_sk,
      ds.web_page_sk,
      ds.total_net_paid,
      ds.total_net_profit,
      ds.total_sales_amount,
      COALESCE(dr.total_refund_amount, 0) AS total_refund_amount,
      COALESCE(dr.total_net_loss, 0) AS total_net_loss,
      COALESCE(dr.total_return_amount, 0) AS total_return_amount,
      ds.total_net_profit - COALESCE(dr.total_net_loss, 0) AS net_profit_adj,
      (ds.total_net_profit - COALESCE(dr.total_net_loss, 0)) / NULLIF(ds.total_net_paid, 0) AS profit_margin,
      ROW_NUMBER() OVER (PARTITION BY ds.channel ORDER BY ds.d_date DESC) AS channel_rn
    FROM daily_sales ds
    LEFT JOIN daily_returns dr
      ON dr.d_date_sk = ds.d_date_sk
      AND dr.channel = ds.channel
      AND dr.call_center_sk = ds.call_center_sk
      AND dr.store_sk = ds.store_sk
      AND dr.web_page_sk = ds.web_page_sk
  ),
  cc_info AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_state,
      cc.cc_country,
      cc.cc_gmt_offset,
      COALESCE(cc.cc_tax_percentage, 0) AS tax_percentage,
      CONCAT(cc.cc_name, ' (', cc.cc_state, ')') AS cc_label
    FROM call_center cc
  ),
  final_calc AS (
    SELECT
      cci.cc_label,
      comb.d_date,
      comb.channel,
      comb.total_sales_amount,
      comb.total_net_paid,
      comb.net_profit_adj,
      comb.profit_margin,
      CASE
        WHEN comb.profit_margin > 0.2 THEN 'High'
        WHEN comb.profit_margin BETWEEN 0.1 AND 0.2 THEN 'Medium'
        ELSE 'Low'
      END AS profit_category,
      CASE
        WHEN comb.profit_margin IS NULL THEN 'N/A'
        WHEN comb.profit_margin < 0 THEN 'Loss'
        ELSE 'Profit'
      END AS profit_status,
      SUM(comb.net_profit_adj) OVER (
        PARTITION BY COALESCE(comb.call_center_sk, -1)
        ORDER BY comb.d_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
      ) AS rolling_7day_profit,
      (SELECT MAX(ds2.total_net_profit)
         FROM daily_sales ds2
        WHERE ds2.call_center_sk = COALESCE(comb.call_center_sk, -1)
          AND ds2.d_date < comb.d_date) AS prior_max_profit,
      (comb.total_return_amount + comb.total_refund_amount) AS total_refunds,
      comb.total_refund_amount,
      comb.total_return_amount
    FROM combined comb
    LEFT JOIN cc_info cci
      ON cci.cc_call_center_sk = comb.call_center_sk
    WHERE comb.total_net_paid IS NOT NULL
  )
SELECT
  cc_label,
  d_date,
  channel,
  total_sales_amount,
  total_net_paid,
  net_profit_adj,
  profit_margin,
  profit_category,
  profit_status,
  rolling_7day_profit,
  prior_max_profit,
  total_refunds,
  CONCAT('Date: ', CAST(d_date AS VARCHAR), ' Channel: ', channel, ' AdjProfit: ', CAST(net_profit_adj AS VARCHAR)) AS report_line
FROM final_calc
WHERE profit_category = 'High'
   OR (profit_margin IS NOT NULL AND profit_margin > 0.15)
ORDER BY d_date DESC, channel, cc_label
LIMIT 100
