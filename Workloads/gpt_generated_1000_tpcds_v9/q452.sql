WITH joined_all AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    cd.cd_credit_rating,
    cd.cd_education_status,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    cs.cs_order_number AS cs_order_number,
    cs.cs_net_paid AS cs_net_paid,
    cs.cs_net_profit AS cs_net_profit,
    cr.cr_return_amount AS cr_return_amount,
    cr.cr_net_loss AS cr_net_loss,
    ss.ss_net_paid AS ss_net_paid,
    ss.ss_net_profit AS ss_net_profit,
    ws.ws_order_number AS ws_order_number,
    ws.ws_net_paid AS ws_net_paid,
    ws.ws_net_profit AS ws_net_profit,
    ws.ws_web_site_sk AS ws_web_site_sk,
    wsite.web_name AS web_name,
    wr.wr_return_amt AS wr_return_amt,
    wr.wr_net_loss AS wr_net_loss
  FROM
    customer c
    LEFT JOIN customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_sales cs
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_sales ss
      ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
  WHERE
    cp.cp_department = 'Electronics'
    AND cd.cd_credit_rating IN ('Low Risk', 'High Risk')
    AND ib.ib_lower_bound >= 50000
),
channel_union AS (
  SELECT
    j.cs_order_number AS order_number,
    j.cs_net_paid AS net_paid,
    'catalog' AS channel,
    j.cp_department AS cp_department,
    j.c_customer_id
  FROM joined_all j
  WHERE j.cs_order_number IS NOT NULL

  UNION ALL

  SELECT
    j.ws_order_number AS order_number,
    j.ws_net_paid AS net_paid,
    'web' AS channel,
    j.cp_department AS cp_department,
    j.c_customer_id
  FROM joined_all j
  WHERE j.ws_order_number IS NOT NULL
),
channel_agg AS (
  SELECT
    channel,
    cp_department,
    SUM(net_paid) AS total_net_paid,
    COUNT(*) AS tx_cnt,
    CASE
      WHEN SUM(net_paid) > 100000 THEN 'High'
      WHEN SUM(net_paid) > 50000 THEN 'Medium'
      ELSE 'Low'
    END AS revenue_category
  FROM channel_union
  GROUP BY GROUPING SETS (
    (channel, cp_department),
    (channel),
    ()
  )
)
SELECT
  ca.channel,
  ca.cp_department,
  ca.total_net_paid,
  ca.tx_cnt,
  ca.revenue_category,
  ca.total_net_paid / NULLIF(ca.tx_cnt, 0) AS avg_net_per_tx,
  ROW_NUMBER() OVER (PARTITION BY ca.channel ORDER BY ca.total_net_paid DESC) AS channel_rank,
  (SELECT AVG(x.total_net_paid)
   FROM (
         SELECT SUM(net_paid) AS total_net_paid
         FROM channel_union
         GROUP BY channel
        ) x) AS avg_channel_net_paid
FROM channel_agg ca
WHERE ca.total_net_paid > (SELECT AVG(total_net_paid) FROM channel_agg)
ORDER BY ca.total_net_paid DESC
LIMIT 100
