WITH sales_agg AS (
  SELECT
    i.i_category,
    i.i_category_id,
    i.i_class,
    i.i_item_sk,
    i.i_product_name,
    'store' AS channel,
    ss.ss_store_sk AS store_sk,
    CAST(NULL AS integer) AS call_center_sk,
    ss.ss_sold_date_sk AS sold_date_sk,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS transaction_cnt,
    CASE WHEN SUM(ss.ss_net_paid) = 0 THEN NULL ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_net_paid) END AS profit_margin
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year IN (1998,1999)
  GROUP BY i.i_category, i.i_category_id, i.i_class, i.i_item_sk, i.i_product_name, ss.ss_store_sk, ss.ss_sold_date_sk, d.d_year, d.d_month_seq

  UNION ALL

  SELECT
    i.i_category,
    i.i_category_id,
    i.i_class,
    i.i_item_sk,
    i.i_product_name,
    'web' AS channel,
    CAST(NULL AS integer) AS store_sk,
    CAST(NULL AS integer) AS call_center_sk,
    ws.ws_sold_date_sk AS sold_date_sk,
    d.d_year,
    d.d_month_seq,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(*) AS transaction_cnt,
    CASE WHEN SUM(ws.ws_net_paid) = 0 THEN NULL ELSE SUM(ws.ws_net_profit) / SUM(ws.ws_net_paid) END AS profit_margin
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year IN (1998,1999)
  GROUP BY i.i_category, i.i_category_id, i.i_class, i.i_item_sk, i.i_product_name, ws.ws_sold_date_sk, d.d_year, d.d_month_seq

  UNION ALL

  SELECT
    i.i_category,
    i.i_category_id,
    i.i_class,
    i.i_item_sk,
    i.i_product_name,
    'catalog' AS channel,
    CAST(NULL AS integer) AS store_sk,
    cs.cs_call_center_sk AS call_center_sk,
    cs.cs_sold_date_sk AS sold_date_sk,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS transaction_cnt,
    CASE WHEN SUM(cs.cs_net_paid) = 0 THEN NULL ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid) END AS profit_margin
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year IN (1998,1999)
  GROUP BY i.i_category, i.i_category_id, i.i_class, i.i_item_sk, i.i_product_name, cs.cs_call_center_sk, cs.cs_sold_date_sk, d.d_year, d.d_month_seq
),

call_center_agg AS (
  SELECT
    cr.cr_call_center_sk,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    MAX(cr.cr_return_quantity) AS max_return_quantity
  FROM catalog_returns cr
  GROUP BY cr.cr_call_center_sk
),

category_summary AS (
  SELECT
    sa.i_category AS category,
    sa.i_category_id,
    sa.i_class,
    sa.channel,
    sa.store_sk,
    sa.call_center_sk,
    sa.d_year,
    sa.d_month_seq,
    SUM(sa.total_net_paid) AS sum_net_paid,
    SUM(sa.total_net_profit) AS sum_net_profit,
    SUM(sa.transaction_cnt) AS total_transactions,
    CASE WHEN SUM(sa.transaction_cnt) = 0 THEN NULL ELSE SUM(sa.total_net_profit) / SUM(sa.transaction_cnt) END AS avg_profit_per_txn,
    MAX(sa.profit_margin) AS max_profit_margin,
    CASE WHEN SUM(sa.total_net_paid) = 0 THEN 0.0 ELSE SUM(sa.total_net_profit) / SUM(sa.total_net_paid) END AS overall_margin,
    CASE WHEN SUM(sa.total_net_paid) > 1000000 THEN 'HIGH' ELSE 'LOW' END AS sales_volume_flag,
    CONCAT(sa.i_category, ':', sa.channel) AS cat_chan_key
  FROM sales_agg sa
  GROUP BY sa.i_category, sa.i_category_id, sa.i_class, sa.channel, sa.store_sk, sa.call_center_sk, sa.d_year, sa.d_month_seq
),

ranked_categories AS (
  SELECT
    cs.*,
    ROW_NUMBER() OVER (PARTITION BY cs.category, cs.channel ORDER BY cs.overall_margin DESC) AS margin_rank,
    RANK() OVER (PARTITION BY cs.channel ORDER BY cs.sum_net_profit DESC) AS profit_rank_global
  FROM category_summary cs
),

final_metrics AS (
  SELECT
    rc.category,
    rc.channel,
    rc.store_sk,
    rc.call_center_sk,
    rc.d_year,
    rc.d_month_seq,
    rc.sum_net_paid,
    rc.sum_net_profit,
    rc.overall_margin,
    rc.margin_rank,
    rc.profit_rank_global,
    COALESCE(cc.total_net_loss, 0) AS call_center_net_loss,
    COALESCE(cc.total_return_amount, 0) AS call_center_return_amount,
    (SELECT SUM(sa.total_net_profit)
     FROM sales_agg sa
     WHERE sa.i_category = rc.category
       AND sa.channel = rc.channel
       AND sa.d_year = rc.d_year - 1) AS prev_year_profit,
    CASE WHEN (SELECT SUM(sa.total_net_profit)
               FROM sales_agg sa
               WHERE sa.i_category = rc.category
                 AND sa.channel = rc.channel
                 AND sa.d_year = rc.d_year - 1) = 0 THEN NULL
         ELSE (rc.sum_net_profit - (SELECT SUM(sa.total_net_profit)
               FROM sales_agg sa
               WHERE sa.i_category = rc.category
                 AND sa.channel = rc.channel
                 AND sa.d_year = rc.d_year - 1)) / NULLIF((SELECT SUM(sa.total_net_profit)
               FROM sales_agg sa
               WHERE sa.i_category = rc.category
                 AND sa.channel = rc.channel
                 AND sa.d_year = rc.d_year - 1), 0) END AS profit_growth_rate,
    (SELECT array_join(array_agg(DISTINCT i2.i_product_name), ', ')
     FROM item i2
     JOIN sales_agg sa2 ON i2.i_item_sk = sa2.i_item_sk
     WHERE sa2.i_category = rc.category
       AND sa2.channel = rc.channel
       AND sa2.d_year = rc.d_year) AS top_products,
    s.s_store_name AS store_name
  FROM ranked_categories rc
  LEFT JOIN call_center_agg cc ON rc.call_center_sk = cc.cr_call_center_sk
  LEFT JOIN store s ON rc.store_sk = s.s_store_sk
  WHERE rc.margin_rank <= 5
    AND rc.sales_volume_flag = 'HIGH'
)

SELECT
  fm.category,
  fm.channel,
  fm.store_sk,
  fm.store_name,
  fm.call_center_sk,
  fm.d_year,
  fm.d_month_seq,
  fm.sum_net_paid,
  fm.sum_net_profit,
  fm.overall_margin,
  fm.margin_rank,
  fm.profit_rank_global,
  fm.call_center_net_loss,
  fm.call_center_return_amount,
  fm.prev_year_profit,
  fm.profit_growth_rate,
  fm.top_products
FROM final_metrics fm
ORDER BY fm.category, fm.channel, fm.margin_rank
