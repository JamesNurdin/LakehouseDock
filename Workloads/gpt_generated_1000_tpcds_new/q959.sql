WITH
  promo_channels AS (
    SELECT
      p.p_promo_sk,
      TRIM(channel) AS channel
    FROM promotion p
    CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel)
  ),

  cs AS (
    SELECT
      cs.cs_order_number,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      c.c_customer_sk,
      c.c_birth_country,
      cd.cd_gender,
      hd.hd_income_band_sk,
      pc.channel,
      t.t_hour
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN promo_channels pc ON p.p_promo_sk = pc.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE c.c_birth_country = 'MEXICO'
      AND p.p_channel_dmail = 'Y'
      AND cs.cs_ext_tax > 20.00
  ),

  ws AS (
    SELECT
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      c.c_customer_sk,
      c.c_birth_country,
      cd.cd_gender,
      hd.hd_income_band_sk,
      pc.channel,
      t.t_hour
    FROM web_sales ws
    TABLESAMPLE BERNOULLI (10)
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN promo_channels pc ON p.p_promo_sk = pc.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE c.c_birth_country = 'MEXICO'
      AND p.p_channel_email = 'Y'
      AND ws.ws_ext_tax > 20.00
  ),

  sr AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_amt,
      sr.sr_net_loss,
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      c.c_customer_sk,
      c.c_birth_country,
      cd.cd_gender,
      hd.hd_income_band_sk,
      s.s_store_id,
      r.r_reason_desc,
      t.t_hour
    FROM store_returns sr
    TABLESAMPLE BERNOULLI (10)
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE c.c_birth_country = 'MEXICO'
      AND s.s_state = 'CA'
      AND sr.sr_return_amt > 100.00
  )

SELECT
  source,
  gender,
  income_band,
  hour,
  SUM(sales_amount) AS total_sales,
  SUM(profit) AS total_profit,
  SUM(return_amount) AS total_return,
  SUM(net_loss) AS total_net_loss,
  COUNT(*) AS txn_cnt,
  COUNT(DISTINCT channel) AS channel_cnt
FROM (
  SELECT
    'catalog' AS source,
    cd_gender AS gender,
    hd_income_band_sk AS income_band,
    t_hour AS hour,
    cs_ext_sales_price AS sales_amount,
    cs_net_profit AS profit,
    CAST(NULL AS decimal(7,2)) AS return_amount,
    CAST(NULL AS decimal(7,2)) AS net_loss,
    channel
  FROM cs

  UNION ALL

  SELECT
    'web' AS source,
    cd_gender,
    hd_income_band_sk,
    t_hour,
    ws_ext_sales_price,
    ws_net_profit,
    CAST(NULL AS decimal(7,2)),
    CAST(NULL AS decimal(7,2)),
    channel
  FROM ws

  UNION ALL

  SELECT
    'store_return' AS source,
    cd_gender,
    hd_income_band_sk,
    t_hour,
    CAST(NULL AS decimal(7,2)),
    CAST(NULL AS decimal(7,2)),
    sr_return_amt,
    sr_net_loss,
    NULL
  FROM sr
) AS unified
GROUP BY GROUPING SETS (
  (source, gender),
  (source, income_band),
  (source, hour),
  (source)
)
ORDER BY source, total_sales DESC
LIMIT 100
