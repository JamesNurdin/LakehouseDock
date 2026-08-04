WITH sales_agg AS (
  SELECT
    cc.cc_name,
    cd.cd_gender,
    cd.cd_demo_sk,
    p.p_promo_name,
    cs.cs_sold_date_sk,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
    COUNT(*) AS order_cnt,
    (SELECT COUNT(*)
       FROM web_returns wr_sub
      WHERE wr_sub.wr_refunded_cdemo_sk = cd.cd_demo_sk) AS total_refunds
  FROM catalog_sales cs
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN web_returns wr
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cs.cs_net_paid_inc_tax > 500
    AND cc.cc_state = 'CA'
    AND p.p_channel_radio = 'N'
  GROUP BY CUBE (cc.cc_name, cd.cd_gender, cd.cd_demo_sk, p.p_promo_name, cs.cs_sold_date_sk)
)
SELECT
  sa.cc_name,
  sa.cd_gender,
  sa.cd_demo_sk,
  sa.p_promo_name,
  sa.cs_sold_date_sk,
  sa.total_net_paid,
  sa.order_cnt,
  sa.total_refunds,
  CASE WHEN sa.total_net_paid > 10000 THEN 'High' ELSE 'Medium' END AS net_category,
  ROW_NUMBER() OVER (PARTITION BY sa.cc_name ORDER BY sa.total_net_paid DESC) AS rn
FROM sales_agg sa
ORDER BY sa.total_net_paid DESC
LIMIT 100
