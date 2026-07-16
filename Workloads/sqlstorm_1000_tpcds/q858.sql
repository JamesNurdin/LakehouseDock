WITH sales_union AS (
  SELECT 
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_store_sk AS store_sk,
    ss.ss_quantity AS quantity,
    ss.ss_net_profit AS net_profit,
    ss.ss_net_paid AS net_paid,
    'store' AS channel,
    COALESCE(s.s_store_name, 'UNKNOWN') AS channel_name,
    p.p_promo_name
  FROM store_sales ss
  LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE ss.ss_sold_date_sk IS NOT NULL

  UNION ALL

  SELECT
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    NULL AS store_sk,
    cs.cs_quantity,
    cs.cs_net_profit,
    cs.cs_net_paid,
    'catalog' AS channel,
    COALESCE(cc.cc_name, 'UNKNOWN') AS channel_name,
    p.p_promo_name
  FROM catalog_sales cs
  LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cs.cs_sold_date_sk IS NOT NULL

  UNION ALL

  SELECT
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    NULL AS store_sk,
    ws.ws_quantity,
    ws.ws_net_profit,
    ws.ws_net_paid,
    'web' AS channel,
    COALESCE(wp.wp_type, 'UNKNOWN') AS channel_name,
    p.p_promo_name
  FROM web_sales ws
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE ws.ws_sold_date_sk IS NOT NULL
),

monthly_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    su.channel,
    max(su.channel_name) AS channel_name,
    sum(su.net_profit) AS total_profit,
    sum(su.net_paid) AS total_paid,
    count(DISTINCT su.item_sk) AS distinct_items,
    avg(su.quantity) AS avg_quantity,
    max(su.net_profit) AS max_profit,
    min(su.net_profit) AS min_profit,
    count(su.p_promo_name) AS promo_count
  FROM sales_union su
  JOIN date_dim d ON su.date_sk = d.d_date_sk
  GROUP BY
    d.d_year,
    d.d_month_seq,
    su.channel
),

ranked_months AS (
  SELECT
    ma.*,
    row_number() OVER (PARTITION BY channel ORDER BY d_month_seq) AS month_seq,
    lag(total_profit) OVER (PARTITION BY channel ORDER BY d_month_seq) AS prev_month_profit,
    (total_profit - lag(total_profit) OVER (PARTITION BY channel ORDER BY d_month_seq)) /
      nullif(lag(total_profit) OVER (PARTITION BY channel ORDER BY d_month_seq), 0) AS profit_change_ratio,
    rank() OVER (PARTITION BY channel ORDER BY total_profit DESC) AS profit_rank
  FROM monthly_agg ma
),

channel_top_item AS (
  SELECT channel, item_sk
  FROM (
    SELECT
      channel,
      item_sk,
      total_profit_item,
      row_number() OVER (PARTITION BY channel ORDER BY total_profit_item DESC) AS rn
    FROM (
      SELECT
        channel,
        item_sk,
        sum(net_profit) AS total_profit_item
      FROM sales_union
      GROUP BY channel, item_sk
    ) agg
  ) numbered
  WHERE rn = 1
),

item_max_sales AS (
  SELECT
    i.i_item_sk,
    i.i_product_name,
    max(su_total.total_paid) AS max_total_paid
  FROM (
    SELECT
      su.item_sk,
      sum(su.net_paid) AS total_paid
    FROM sales_union su
    GROUP BY su.item_sk
  ) su_total
  JOIN item i ON su_total.item_sk = i.i_item_sk
  GROUP BY i.i_item_sk, i.i_product_name
)

SELECT
  rm.d_year,
  rm.d_month_seq,
  rm.channel,
  rm.channel_name,
  rm.total_profit,
  rm.total_paid,
  rm.distinct_items,
  rm.avg_quantity,
  rm.max_profit,
  rm.min_profit,
  rm.promo_count,
  rm.profit_change_ratio,
  rm.profit_rank,
  CASE 
    WHEN rm.profit_change_ratio IS NULL THEN 'N/A'
    WHEN rm.profit_change_ratio > 0 THEN 'UP'
    ELSE 'DOWN'
  END AS profit_trend,
  concat(upper(rm.channel), ':M', format('%02d', rm.d_month_seq)) AS channel_label,
  im.max_total_paid,
  (SELECT avg(cs.cs_net_paid)
   FROM catalog_sales cs
   WHERE cs.cs_item_sk = cti.item_sk) AS avg_catalog_paid
FROM ranked_months rm
LEFT JOIN channel_top_item cti ON rm.channel = cti.channel
LEFT JOIN item_max_sales im ON im.i_item_sk = cti.item_sk
WHERE rm.d_year = 2001
ORDER BY rm.d_year, rm.d_month_seq, rm.total_profit DESC
LIMIT 100
