WITH cs_join AS (
  SELECT cs.cs_item_sk,
         cs.cs_order_number,
         cs.cs_sold_date_sk,
         cs.cs_net_paid_inc_tax,
         cs.cs_net_profit,
         cs.cs_promo_sk,
         cs.cs_bill_cdemo_sk,
         cs.cs_bill_hdemo_sk,
         cs.cs_bill_addr_sk,
         CAST(NULL AS INTEGER) AS web_site_sk
  FROM catalog_sales cs
  JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
),
ws_join AS (
  SELECT ws.ws_item_sk        AS cs_item_sk,
         ws.ws_order_number   AS cs_order_number,
         ws.ws_sold_date_sk   AS cs_sold_date_sk,
         ws.ws_net_paid_inc_tax AS cs_net_paid_inc_tax,
         ws.ws_net_profit     AS cs_net_profit,
         ws.ws_promo_sk       AS cs_promo_sk,
         ws.ws_bill_cdemo_sk  AS cs_bill_cdemo_sk,
         ws.ws_bill_hdemo_sk  AS cs_bill_hdemo_sk,
         ws.ws_bill_addr_sk   AS cs_bill_addr_sk,
         ws.ws_web_site_sk    AS web_site_sk
  FROM web_sales ws
  JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
),
sales_union AS (
  SELECT * FROM cs_join
  UNION DISTINCT
  SELECT * FROM ws_join
),
store_full AS (
  SELECT sr.sr_return_quantity,
         sr.sr_return_amt,
         sr.sr_store_sk,
         s.s_store_name,
         cd.cd_demo_sk   AS sr_cd_demo_sk,
         hd.hd_demo_sk   AS sr_hd_demo_sk,
         ca.ca_address_sk AS sr_ca_address_sk
  FROM store_returns sr
  FULL OUTER JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
),
seq_set AS (
  SELECT 1 AS seq UNION ALL SELECT 2 AS seq
),
small_demo AS (
  SELECT cd_demo_sk, cd_gender
  FROM customer_demographics
  WHERE cd_gender = 'M'
)
SELECT
  p.p_promo_name,
  cd_bill.cd_gender,
  wsit.web_name,
  SUM(su.cs_net_paid_inc_tax) AS total_net_paid,
  SUM(su.cs_net_profit)      AS total_profit,
  CASE WHEN SUM(su.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_category,
  s.seq
FROM sales_union su
JOIN promotion p
  ON su.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_bill
  ON su.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON su.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill
  ON su.cs_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN web_site wsit
  ON su.web_site_sk = wsit.web_site_sk
LEFT JOIN store_full sf
  ON TRUE
CROSS JOIN small_demo d
CROSS JOIN seq_set s
GROUP BY CUBE (p.p_promo_name, cd_bill.cd_gender, wsit.web_name, s.seq)
ORDER BY total_net_paid DESC
LIMIT 100
