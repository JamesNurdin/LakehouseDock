WITH sales_promo AS (
  SELECT
    p.p_promo_id AS promo_id,
    p.p_promo_name AS promo_name,
    CASE
      WHEN p.p_discount_active = 'Y' THEN cs.cs_net_paid_inc_ship * 0.9
      ELSE cs.cs_net_paid_inc_ship
    END AS adjusted_net_paid,
    chan.channel AS channel
  FROM catalog_sales cs
  FULL OUTER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN LATERAL (
    SELECT channel_val AS channel
    FROM UNNEST(ARRAY[p.p_channel_dmail, p.p_channel_email, p.p_channel_tv]) AS t(channel_val)
  ) AS chan ON true
  WHERE cs.cs_net_paid_inc_ship > 500
    AND (p.p_channel_radio = 'N' OR p.p_channel_radio IS NULL)
),
returns_anti AS (
  SELECT
    CAST(hd.hd_demo_sk AS VARCHAR) AS promo_id,
    CASE WHEN sr.sr_return_amt > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS promo_name,
    sr.sr_return_amt AS adjusted_net_paid,
    NULL AS channel
  FROM store_returns sr
  JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_hdemo_sk = sr.sr_hdemo_sk
      AND cs2.cs_item_sk = sr.sr_item_sk
  )
)
SELECT promo_id,
       promo_name,
       adjusted_net_paid,
       channel
FROM sales_promo
WHERE promo_id IS NOT NULL
UNION ALL
SELECT promo_id,
       promo_name,
       adjusted_net_paid,
       channel
FROM returns_anti
ORDER BY adjusted_net_paid DESC
LIMIT 100
