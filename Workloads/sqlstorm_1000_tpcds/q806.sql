WITH all_sales AS (
  SELECT cs_sold_date_sk AS sales_date_sk,
         cs_sold_time_sk AS sales_time_sk,
         cs_item_sk AS item_sk,
         cs_order_number AS order_number,
         cs_quantity AS quantity,
         cs_net_paid AS net_paid,
         cs_net_profit AS net_profit,
         'catalog' AS channel,
         cs_promo_sk AS promo_sk
  FROM catalog_sales
  UNION ALL
  SELECT ss_sold_date_sk,
         ss_sold_time_sk,
         ss_item_sk,
         ss_ticket_number,
         ss_quantity,
         ss_net_paid,
         ss_net_profit,
         'store',
         ss_promo_sk
  FROM store_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_sold_time_sk,
         ws_item_sk,
         ws_order_number,
         ws_quantity,
         ws_net_paid,
         ws_net_profit,
         'web',
         ws_promo_sk
  FROM web_sales
),
sales_augmented AS (
  SELECT a.sales_date_sk,
         d.d_date,
         d.d_year,
         d.d_month_seq,
         d.d_week_seq,
         a.sales_time_sk,
         a.item_sk,
         i.i_item_id,
         i.i_product_name,
         i.i_category,
         i.i_brand,
         COALESCE(i.i_color, 'UNKNOWN') AS color,
         a.quantity,
         a.net_paid,
         a.net_profit,
         a.channel,
         a.promo_sk,
         p.p_promo_name,
         p.p_discount_active,
         CONCAT_WS(' | ', i.i_product_name, i.i_category, COALESCE(p.p_promo_name, 'NO_PROMO')) AS product_promo_desc,
         CASE WHEN NULLIF(a.net_paid, 0) IS NOT NULL THEN a.net_profit / NULLIF(a.net_paid, 0) ELSE NULL END AS profit_margin,
         SUBSTRING(i.i_product_name FROM 1 FOR 10) AS product_name_prefix,
         CASE WHEN a.net_profit > 0 AND p.p_discount_active = 'Y' THEN TRUE ELSE FALSE END AS profitable_promo,
         CASE
           WHEN a.net_paid > 10000 THEN 'HIGH'
           WHEN a.net_paid < 0 THEN 'NEGATIVE'
           ELSE 'NORMAL'
         END AS paid_bucket
  FROM all_sales a
  LEFT JOIN date_dim d ON a.sales_date_sk = d.d_date_sk
  LEFT JOIN item i ON a.item_sk = i.i_item_sk
  LEFT JOIN promotion p ON a.promo_sk = p.p_promo_sk
),
sales_with_history AS (
  SELECT s.*,
         (SELECT MAX(s2.net_profit)
          FROM sales_augmented s2
          WHERE s2.item_sk = s.item_sk
            AND s2.d_date < s.d_date) AS max_prior_profit,
         ROW_NUMBER() OVER (PARTITION BY s.item_sk ORDER BY s.d_date) AS seq_in_item,
         DENSE_RANK() OVER (PARTITION BY s.channel ORDER BY s.profit_margin DESC) AS profit_rank_by_channel,
         SUM(s.net_paid) OVER (PARTITION BY s.item_sk ORDER BY s.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_paid,
         APPROX_PERCENTILE(s.net_profit, 0.5) OVER (PARTITION BY s.item_sk) AS median_profit_item,
         COALESCE(s.i_category, 'MISC') AS category_filled
  FROM sales_augmented s
),
final_result AS (
  SELECT sw.item_sk,
         sw.channel,
         sw.d_date,
         sw.net_profit,
         sw.profit_margin,
         sw.max_prior_profit,
         sw.profit_rank_by_channel,
         sw.cum_net_paid,
         sw.paid_bucket,
         cc.cc_name AS call_center_name,
         sw.product_promo_desc
  FROM sales_with_history sw
  LEFT JOIN call_center cc ON cc.cc_division = mod(sw.item_sk, 10)
  WHERE (sw.profit_margin IS NOT NULL AND sw.profit_margin > 0.05)
     OR (sw.paid_bucket = 'HIGH')
     OR (cc.cc_tax_percentage IS NOT DISTINCT FROM 0.00)
     OR EXISTS (SELECT 1 FROM promotion p2 WHERE p2.p_promo_sk = sw.promo_sk AND p2.p_discount_active = 'Y')
),
aggregate_summary AS (
  SELECT NULL AS item_sk,
         'summary' AS channel,
         NULL AS d_date,
         SUM(net_profit) AS net_profit,
         NULL AS profit_margin,
         NULL AS max_prior_profit,
         NULL AS profit_rank_by_channel,
         SUM(cum_net_paid) AS cum_net_paid,
         'AGG' AS paid_bucket,
         NULL AS call_center_name,
         NULL AS product_promo_desc
  FROM final_result
  WHERE paid_bucket = 'HIGH'
)
SELECT *
FROM (
    SELECT *
    FROM final_result
    WHERE profit_margin > 0.1
)
UNION ALL
SELECT *
FROM (
    SELECT *
    FROM aggregate_summary
    INTERSECT
    SELECT *
    FROM final_result
    WHERE paid_bucket = 'HIGH'
)
