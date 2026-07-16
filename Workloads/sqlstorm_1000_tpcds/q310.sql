WITH
  sales_union AS (
    SELECT
      ss.ss_item_sk AS item_sk,
      ss.ss_sold_date_sk AS date_sk,
      ss.ss_store_sk AS channel_sk,
      ss.ss_quantity AS quantity,
      ss.ss_ext_sales_price AS ext_sales,
      ss.ss_net_profit AS profit,
      ss.ss_promo_sk AS promo_sk,
      ss.ss_customer_sk AS customer_sk,
      'store' AS sales_channel
    FROM store_sales ss
    UNION ALL
    SELECT
      cs.cs_item_sk AS item_sk,
      cs.cs_sold_date_sk AS date_sk,
      cs.cs_call_center_sk AS channel_sk,
      cs.cs_quantity AS quantity,
      cs.cs_ext_sales_price AS ext_sales,
      cs.cs_net_profit AS profit,
      cs.cs_promo_sk AS promo_sk,
      cs.cs_bill_customer_sk AS customer_sk,
      'catalog' AS sales_channel
    FROM catalog_sales cs
  ),
  category_sales AS (
    SELECT
      i.i_category AS category,
      d.d_year,
      d.d_month_seq,
      DATE_FORMAT(d.d_date, '%Y-%m') AS year_month,
      s.sales_channel,
      COALESCE(p.p_discount_active, 'N') AS promo_active_flag,
      MIN(COALESCE(st.s_store_name, cc.cc_name, 'UNKNOWN')) AS channel_name,
      SUM(s.quantity) AS total_qty,
      SUM(s.ext_sales) AS total_sales,
      SUM(s.profit) AS total_profit,
      AVG(CASE WHEN s.ext_sales > 0 THEN s.profit / s.ext_sales ELSE 0 END) AS avg_profit_ratio,
      COUNT(DISTINCT s.customer_sk) AS distinct_customers
    FROM sales_union s
    JOIN item i ON s.item_sk = i.i_item_sk
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
    LEFT JOIN store st ON s.sales_channel = 'store' AND s.channel_sk = st.s_store_sk
    LEFT JOIN call_center cc ON s.sales_channel = 'catalog' AND s.channel_sk = cc.cc_call_center_sk
    GROUP BY
      i.i_category,
      d.d_year,
      d.d_month_seq,
      DATE_FORMAT(d.d_date, '%Y-%m'),
      s.sales_channel,
      COALESCE(p.p_discount_active, 'N')
  ),
  ranked_category_sales AS (
    SELECT
      cs.*,
      ROW_NUMBER() OVER (PARTITION BY cs.year_month, cs.sales_channel ORDER BY cs.total_profit DESC) AS profit_rank
    FROM category_sales cs
  )
SELECT
  rcs.year_month,
  rcs.sales_channel,
  rcs.category,
  rcs.channel_name,
  rcs.total_qty,
  rcs.total_sales,
  rcs.total_profit,
  rcs.avg_profit_ratio,
  rcs.distinct_customers,
  rcs.promo_active_flag,
  rcs.profit_rank,
  COALESCE(
    (SELECT COUNT(DISTINCT ss2.ss_store_sk)
     FROM store_sales ss2
     JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
     JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
     WHERE i2.i_category = rcs.category
       AND DATE_FORMAT(d2.d_date, '%Y-%m') = rcs.year_month), 0) AS stores_selling_item,
  COALESCE(
    (SELECT COUNT(DISTINCT ss2.ss_customer_sk)
     FROM store_sales ss2
     JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
     JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
     WHERE i2.i_category = rcs.category
       AND DATE_FORMAT(d2.d_date, '%Y-%m') = rcs.year_month), 0) AS distinct_customers_sold,
  CONCAT(rcs.category, ' - ', rcs.sales_channel) AS category_channel_label,
  CASE
    WHEN rcs.total_profit > 0 THEN 'PROFITABLE'
    WHEN rcs.total_profit < 0 THEN 'LOSS'
    ELSE 'NEUTRAL'
  END AS profit_status
FROM ranked_category_sales rcs
WHERE rcs.profit_rank <= 5
ORDER BY rcs.year_month, rcs.sales_channel, rcs.profit_rank
