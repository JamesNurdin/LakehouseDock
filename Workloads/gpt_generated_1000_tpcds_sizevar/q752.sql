/*
  Goal: Analyse the contribution of promotions to sales across store and catalog channels, applying string pattern filters, extracting textual information, categorising profit status, and enriching each row with a correlated inventory total. The query samples the sales tables, unions the two channels, de‑duplicates, aggregates and returns the top 100 promotion‑level results.
*/
WITH
  store_sales_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
  ),
  catalog_sales_sample AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
  ),
  store_agg AS (
    SELECT
      ss.ss_item_sk                                      AS item_sk,
      ss.ss_sold_date_sk                                 AS date_sk,
      ss.ss_sold_time_sk                                 AS time_sk,
      p.p_promo_sk                                       AS promo_sk,
      p.p_promo_name                                     AS promo_name,
      concat(p.p_promo_name, ' - ', p.p_channel_details) AS promo_desc,
      CASE WHEN ss.ss_net_profit > 0 THEN 'profitable' ELSE 'loss' END AS profit_flag,
      SUM(ss.ss_net_paid)                                AS total_net_paid,
      COUNT(*)                                           AS sales_cnt,
      (
        SELECT SUM(i.inv_quantity_on_hand)
        FROM inventory i
        WHERE i.inv_item_sk = ss.ss_item_sk
          AND i.inv_date_sk = ss.ss_sold_date_sk
      )                                                 AS total_inventory_on_day
    FROM store_sales_sample ss
    JOIN date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t   ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p  ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_promo_name LIKE '%discount%'
      AND regexp_like(p.p_channel_details, '[A-Z][a-z]{3,}')
    GROUP BY
      ss.ss_item_sk,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      p.p_promo_sk,
      p.p_promo_name,
      concat(p.p_promo_name, ' - ', p.p_channel_details),
      CASE WHEN ss.ss_net_profit > 0 THEN 'profitable' ELSE 'loss' END
  ),
  catalog_agg AS (
    SELECT
      cs.cs_item_sk                                      AS item_sk,
      cs.cs_sold_date_sk                                 AS date_sk,
      cs.cs_sold_time_sk                                 AS time_sk,
      p.p_promo_sk                                       AS promo_sk,
      p.p_promo_name                                     AS promo_name,
      concat(p.p_promo_name, ' - ', p.p_channel_details) AS promo_desc,
      CASE WHEN cs.cs_net_profit > 0 THEN 'profitable' ELSE 'loss' END AS profit_flag,
      SUM(cs.cs_net_paid)                                AS total_net_paid,
      COUNT(*)                                           AS sales_cnt,
      (
        SELECT SUM(i.inv_quantity_on_hand)
        FROM inventory i
        WHERE i.inv_item_sk = cs.cs_item_sk
          AND i.inv_date_sk = cs.cs_sold_date_sk
      )                                                AS total_inventory_on_day
    FROM catalog_sales_sample cs
    JOIN date_dim d   ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t   ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p  ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE regexp_like(cc.cc_name, '^.*Center.*$')
      AND p.p_promo_name LIKE '%sale%'
    GROUP BY
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      p.p_promo_sk,
      p.p_promo_name,
      concat(p.p_promo_name, ' - ', p.p_channel_details),
      CASE WHEN cs.cs_net_profit > 0 THEN 'profitable' ELSE 'loss' END
  ),
  union_all AS (
    SELECT * FROM store_agg
    UNION
    SELECT * FROM catalog_agg
  )
SELECT
  u.promo_sk,
  u.promo_name,
  u.profit_flag,
  SUM(u.total_net_paid)        AS agg_net_paid,
  SUM(u.sales_cnt)            AS agg_sales_cnt,
  SUM(u.total_inventory_on_day) AS agg_inventory_qty
FROM union_all u
GROUP BY
  u.promo_sk,
  u.promo_name,
  u.profit_flag
ORDER BY agg_net_paid DESC
LIMIT 100
