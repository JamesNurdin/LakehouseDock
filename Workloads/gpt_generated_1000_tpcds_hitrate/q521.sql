WITH
  base_metrics AS (
    SELECT
      p.p_promo_id,
      p.p_channel_tv,
      p.p_channel_email,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit
    FROM tpcds.promotion p
    JOIN tpcds.web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_wholesale_cost > 20
    GROUP BY ROLLUP (p.p_channel_tv, p.p_channel_email, p.p_promo_id)
  ),
  dim_channels AS (
    SELECT DISTINCT
      p.p_channel_tv AS channel_tv,
      p.p_channel_email AS channel_email
    FROM tpcds.promotion p
    WHERE p.p_channel_tv = 'Y' OR p.p_channel_email = 'Y'
    LIMIT 5
  )
SELECT
  dm.channel_tv,
  dm.channel_email,
  bm.p_promo_id,
  bm.total_sales,
  bm.total_profit
FROM dim_channels dm
CROSS JOIN (
  SELECT *
  FROM base_metrics
  WHERE p_channel_tv IS NOT NULL AND p_channel_email IS NOT NULL
) bm
WHERE dm.channel_tv = bm.p_channel_tv AND dm.channel_email = bm.p_channel_email
UNION
SELECT
  dm.channel_tv,
  dm.channel_email,
  bm.p_promo_id,
  bm.total_sales,
  bm.total_profit
FROM dim_channels dm
CROSS JOIN (
  SELECT *
  FROM base_metrics
  WHERE p_channel_tv IS NULL OR p_channel_email IS NULL
) bm
WHERE dm.channel_tv = bm.p_channel_tv OR dm.channel_email = bm.p_channel_email
ORDER BY total_sales DESC
LIMIT 100
