WITH
  full_join AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_warehouse_sk,
      cs.cs_order_number,
      cs.cs_net_profit,
      cr.cr_return_amount,
      cr.cr_net_loss
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
      ON cs.cs_item_sk = cr.cr_item_sk
     AND cs.cs_order_number = cr.cr_order_number
  ),

  promo_channels AS (
    SELECT
      p.p_promo_sk,
      p.p_promo_id,
      p.p_item_sk,
      channel
    FROM promotion p
    CROSS JOIN UNNEST(ARRAY[
      CASE WHEN p.p_channel_dmail = 'Y' THEN 'dmail' END,
      CASE WHEN p.p_channel_email = 'Y' THEN 'email' END,
      CASE WHEN p.p_channel_catalog = 'Y' THEN 'catalog' END,
      CASE WHEN p.p_channel_tv = 'Y' THEN 'tv' END,
      CASE WHEN p.p_channel_radio = 'Y' THEN 'radio' END,
      CASE WHEN p.p_channel_press = 'Y' THEN 'press' END,
      CASE WHEN p.p_channel_event = 'Y' THEN 'event' END,
      CASE WHEN p.p_channel_demo = 'Y' THEN 'demo' END
    ]) AS t(channel)
    WHERE channel IS NOT NULL
  ),

  top_items AS (
    SELECT
      fj.cs_warehouse_sk,
      fj.cs_item_sk,
      fj.cs_net_profit,
      ROW_NUMBER() OVER (PARTITION BY fj.cs_warehouse_sk ORDER BY fj.cs_net_profit DESC) AS rn
    FROM full_join fj
    WHERE fj.cs_net_profit IS NOT NULL
  ),

  ranked_items AS (
    SELECT *
    FROM top_items
    WHERE rn <= 5
  ),

  final_base AS (
    SELECT
      ri.cs_warehouse_sk,
      w.w_warehouse_name,
      ri.cs_item_sk,
      i.i_product_name AS product_name,
      ri.cs_net_profit,
      (SELECT SUM(cs2.cs_ext_sales_price)
         FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = ri.cs_item_sk) AS total_sales_price,
      p.p_promo_id,
      pc.channel
    FROM ranked_items ri
    JOIN warehouse w ON ri.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON ri.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    LEFT JOIN promo_channels pc ON pc.p_promo_sk = p.p_promo_sk
  ),

  store_part AS (
    SELECT
      NULL AS cs_warehouse_sk,
      NULL AS w_warehouse_name,
      sr.sr_item_sk AS cs_item_sk,
      i.i_product_name AS product_name,
      NULL AS cs_net_profit,
      (SELECT SUM(cs3.cs_ext_sales_price)
         FROM catalog_sales cs3
        WHERE cs3.cs_item_sk = sr.sr_item_sk) AS total_sales_price,
      NULL AS p_promo_id,
      r.r_reason_desc AS channel
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 0
  )
SELECT
  fb.cs_warehouse_sk,
  fb.w_warehouse_name,
  fb.cs_item_sk,
  fb.product_name,
  fb.cs_net_profit,
  fb.total_sales_price,
  fb.p_promo_id,
  fb.channel
FROM final_base fb
UNION
SELECT
  sp.cs_warehouse_sk,
  sp.w_warehouse_name,
  sp.cs_item_sk,
  sp.product_name,
  sp.cs_net_profit,
  sp.total_sales_price,
  sp.p_promo_id,
  sp.channel
FROM store_part sp
EXCEPT
SELECT
  fj.cs_warehouse_sk,
  NULL,
  fj.cs_item_sk,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL
FROM full_join fj
WHERE fj.cr_return_amount IS NOT NULL
ORDER BY cs_warehouse_sk NULLS LAST, cs_net_profit DESC
LIMIT 100
