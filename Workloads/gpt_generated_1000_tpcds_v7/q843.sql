WITH catalog_agg AS (
  SELECT
    cs.cs_sold_date_sk AS sold_date_sk,
    t.t_hour,
    i.i_category,
    SUM(cs.cs_ext_sales_price) AS sales_amount,
    'catalog' AS sales_channel
  FROM tpcds.catalog_sales cs
  JOIN tpcds.time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  WHERE hd.hd_buy_potential = '1001-5000'
    AND p.p_discount_active = 'Y'
    AND t.t_hour BETWEEN 9 AND 18
  GROUP BY cs.cs_sold_date_sk, t.t_hour, i.i_category
),
web_agg AS (
  SELECT
    ws.ws_sold_date_sk AS sold_date_sk,
    t.t_hour,
    i.i_category,
    SUM(ws.ws_ext_sales_price) AS sales_amount,
    'web' AS sales_channel
  FROM tpcds.web_sales ws
  JOIN tpcds.time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN tpcds.item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN tpcds.household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  WHERE hd.hd_buy_potential = '1001-5000'
    AND p.p_discount_active = 'Y'
    AND t.t_hour BETWEEN 9 AND 18
  GROUP BY ws.ws_sold_date_sk, t.t_hour, i.i_category
)
SELECT
  sold_date_sk,
  t_hour,
  i_category,
  SUM(sales_amount) AS total_sales,
  COUNT(DISTINCT sales_channel) AS channels_present
FROM (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM web_agg
) combined
GROUP BY sold_date_sk, t_hour, i_category
ORDER BY total_sales DESC
LIMIT 100
