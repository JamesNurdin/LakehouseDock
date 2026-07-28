WITH
  store_agg AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      concat(i.i_brand, '-', i.i_class) AS brand_class,
      regexp_extract(i.i_item_desc, '^(\\w+)', 1) AS first_word,
      SUM(sr.sr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt,
      CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(i.i_item_desc, '(?i)gold')
      AND i.i_item_desc LIKE '%Pro%'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_brand, i.i_class, i.i_item_desc
  ),
  catalog_agg AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      concat(i.i_brand, '-', i.i_class) AS brand_class,
      regexp_extract(i.i_item_desc, '^(\\w+)', 1) AS first_word,
      SUM(cr.cr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt,
      CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(w.w_city, '^A.*')
      AND i.i_item_desc LIKE '%Gold%'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_brand, i.i_class, i.i_item_desc
  )
SELECT
  i_item_sk,
  i_item_id,
  brand_class,
  first_word,
  total_net_loss,
  return_cnt,
  loss_category
FROM store_agg
UNION ALL
SELECT
  i_item_sk,
  i_item_id,
  brand_class,
  first_word,
  total_net_loss,
  return_cnt,
  loss_category
FROM catalog_agg
ORDER BY loss_category, total_net_loss DESC
