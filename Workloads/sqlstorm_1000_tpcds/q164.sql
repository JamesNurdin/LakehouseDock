WITH
  sales_union AS (
    SELECT
      cs.cs_sold_date_sk AS date_sk,
      cs.cs_item_sk AS item_sk,
      cs.cs_quantity AS quantity,
      cs.cs_net_paid AS net_paid,
      'catalog' AS sales_channel,
      cs.cs_order_number AS order_number,
      cs.cs_call_center_sk AS call_center_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      'store',
      ss.ss_ticket_number,
      NULL
    FROM store_sales ss
    UNION ALL
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      'web',
      ws.ws_order_number,
      NULL
    FROM web_sales ws
  ),
  returns_union AS (
    SELECT
      cr.cr_returned_date_sk AS date_sk,
      cr.cr_item_sk AS item_sk,
      cr.cr_return_quantity AS quantity,
      -cr.cr_return_amount AS net_paid,
      'catalog' AS return_channel,
      cr.cr_order_number AS order_number
    FROM catalog_returns cr
    UNION ALL
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_item_sk,
      sr.sr_return_quantity,
      -sr.sr_return_amt,
      'store',
      sr.sr_ticket_number
    FROM store_returns sr
    UNION ALL
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_return_quantity,
      -wr.wr_return_amt,
      'web',
      wr.wr_order_number
    FROM web_returns wr
  ),
  item_sales AS (
    SELECT
      su.item_sk,
      su.sales_channel,
      su.date_sk,
      COALESCE(d.d_date, DATE '1900-01-01') AS sale_date,
      su.quantity,
      su.net_paid,
      CASE
        WHEN su.sales_channel = 'catalog' AND i.i_class = 'P' THEN 'P_CLASS'
        WHEN su.sales_channel = 'store' AND i.i_category = 'PRO' THEN 'PRO_CAT'
        ELSE 'OTHER'
      END AS sales_bucket,
      ROW_NUMBER() OVER (PARTITION BY su.item_sk, su.sales_channel ORDER BY su.net_paid DESC) AS rn
    FROM sales_union su
    LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
    LEFT JOIN item i ON su.item_sk = i.i_item_sk
  ),
  item_returns AS (
    SELECT
      ru.item_sk,
      ru.return_channel,
      ru.date_sk,
      COALESCE(d.d_date, DATE '1900-01-01') AS return_date,
      ru.quantity,
      ru.net_paid,
      ROW_NUMBER() OVER (PARTITION BY ru.item_sk, ru.return_channel ORDER BY ru.net_paid ASC) AS rn_ret
    FROM returns_union ru
    LEFT JOIN date_dim d ON ru.date_sk = d.d_date_sk
  ),
  latest_sales AS (
    SELECT *
    FROM item_sales
    WHERE rn = 1
  ),
  latest_returns AS (
    SELECT *
    FROM item_returns
    WHERE rn_ret = 1
  ),
  combined AS (
    SELECT
      ls.item_sk,
      ls.sales_channel,
      ls.sale_date,
      ls.quantity AS sold_qty,
      ls.net_paid AS sold_net,
      COALESCE(lr.return_date, DATE '9999-12-31') AS last_return_date,
      COALESCE(lr.quantity, 0) AS returned_qty,
      COALESCE(lr.net_paid, 0) AS returned_net,
      CASE
        WHEN lr.return_date IS NULL THEN 'NO_RETURN'
        WHEN lr.return_date > ls.sale_date THEN 'POST_RETURN'
        ELSE 'PRE_RETURN'
      END AS return_timing,
      CASE
        WHEN (ls.net_paid + COALESCE(lr.net_paid,0)) < 0 THEN NULL
        ELSE (ls.net_paid + COALESCE(lr.net_paid,0))
      END AS net_after_returns,
      CASE
        WHEN i.i_manager_id IS NULL THEN 'UNKNOWN_MGR'
        ELSE CAST(i.i_manager_id AS VARCHAR)
      END AS manager_id_str,
      CONCAT('SKU-', CAST(ls.item_sk AS VARCHAR), '-', COALESCE(ls.sales_channel, 'NA')) AS sku_key,
      CASE
        WHEN ls.quantity = 0 THEN NULL
        ELSE (ls.net_paid / NULLIF(ls.quantity,0))
      END AS profit_per_unit,
      CASE
        WHEN REGEXP_LIKE(i.i_product_name, '^.*(Pro|Plus).*$') AND DATE_DIFF('day', ls.sale_date, DATE '2024-10-01') < 365 THEN 'RECENT_PRO'
        ELSE 'OTHER'
      END AS product_recency_flag,
      (SELECT AVG(net_paid) FROM sales_union su WHERE su.item_sk = ls.item_sk) AS avg_item_net_across_channels,
      CASE
        WHEN NOT EXISTS (SELECT 1 FROM returns_union ru WHERE ru.item_sk = ls.item_sk) THEN 'NEVER_RETURNED'
        ELSE 'RETURNED_SOME'
      END AS return_status,
      (SELECT COUNT(*) FROM promotion p
       WHERE p.p_item_sk = ls.item_sk
         AND ls.date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk) AS promo_active_count,
      (SELECT COALESCE(SUM(p.p_cost), 0) FROM promotion p
       WHERE p.p_item_sk = ls.item_sk
         AND ls.date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk) AS promo_total_cost,
      CASE
        WHEN i.i_product_name IS NULL THEN 'NO_NAME'
        ELSE SUBSTRING(i.i_product_name FROM 1 FOR 15)
      END AS product_name_prefix,
      CASE
        WHEN i.i_product_name IS NOT NULL THEN REPLACE(i.i_product_name, ' ', '_')
        ELSE NULL
      END AS product_name_underscored,
      ls.sales_bucket
    FROM latest_sales ls
    LEFT JOIN latest_returns lr
      ON ls.item_sk = lr.item_sk
     AND ls.sales_channel = lr.return_channel
    LEFT JOIN item i ON ls.item_sk = i.i_item_sk
  ),
  union_set AS (
    SELECT *
    FROM combined
    WHERE net_after_returns IS NOT NULL
    UNION ALL
    SELECT *
    FROM combined
    WHERE net_after_returns IS NULL AND return_status = 'NEVER_RETURNED'
  ),
  final_set AS (
    SELECT *
    FROM union_set
    EXCEPT
    SELECT *
    FROM combined
    WHERE sales_bucket = 'OTHER' AND profit_per_unit IS NULL
  )
SELECT
  f.item_sk,
  f.sales_channel,
  f.sku_key,
  f.sale_date,
  f.sold_qty,
  f.returned_qty,
  f.net_after_returns,
  f.manager_id_str,
  f.product_recency_flag,
  ROUND(f.avg_item_net_across_channels, 2) AS avg_item_net_across_channels,
  f.return_status,
  f.promo_active_count,
  ROUND(f.promo_total_cost, 2) AS promo_total_cost,
  f.product_name_prefix,
  f.product_name_underscored,
  ROW_NUMBER() OVER (PARTITION BY f.item_sk ORDER BY f.net_after_returns DESC NULLS LAST) AS rank_by_net,
  COUNT(*) OVER (PARTITION BY f.sales_channel) AS channel_item_count,
  CASE
    WHEN f.net_after_returns > 0 THEN 'POSITIVE'
    WHEN f.net_after_returns = 0 THEN 'ZERO'
    ELSE 'NEGATIVE'
  END AS net_sign_indicator,
  TRY_CAST(NULLIF(f.sku_key, '') AS BIGINT) AS sku_key_as_bigint
FROM final_set f
WHERE
  (f.sales_channel = 'catalog' AND f.return_timing = 'NO_RETURN')
  OR (f.sales_channel = 'store' AND f.return_timing = 'POST_RETURN')
  OR (f.sales_channel = 'web' AND f.return_timing <> 'PRE_RETURN')
ORDER BY f.item_sk, f.sales_channel
