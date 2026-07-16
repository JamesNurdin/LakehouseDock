WITH
sales_by_channel AS (
  SELECT
    'store' AS channel,
    ss.ss_sold_date_sk AS date_sk,
    dd.d_year,
    ss.ss_customer_sk AS cust_sk,
    c.c_customer_id,
    ss.ss_item_sk,
    i.i_product_name,
    ss.ss_quantity,
    ss.ss_ext_sales_price AS sales,
    ss.ss_net_profit AS profit,
    COALESCE(p.p_discount_active, 'N') AS promo_active,
    CASE
      WHEN ss.ss_quantity > 10 THEN 'Bulk'
      ELSE 'Regular'
    END AS sales_type,
    NULLIF(ss.ss_coupon_amt, 0.0) AS coupon_amount,
    (SELECT MAX(cs2.cs_ext_sales_price) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = ss.ss_item_sk) AS max_catalog_sale_for_item,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = ss.ss_item_sk AND sr.sr_store_sk = ss.ss_store_sk) AS returns_count
  FROM store_sales ss
  LEFT JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
  LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE ss.ss_net_profit IS NOT NULL
),
web_sales_extended AS (
  SELECT
    'web' AS channel,
    ws.ws_sold_date_sk AS date_sk,
    dd.d_year,
    ws.ws_bill_customer_sk AS cust_sk,
    c.c_customer_id,
    ws.ws_item_sk,
    i.i_product_name,
    ws.ws_quantity,
    ws.ws_ext_sales_price AS sales,
    ws.ws_net_profit AS profit,
    COALESCE(p.p_discount_active, 'N') AS promo_active,
    CASE
      WHEN ws.ws_quantity > 10 THEN 'Bulk' ELSE 'Regular'
    END AS sales_type,
    NULLIF(ws.ws_coupon_amt, 0.0) AS coupon_amount,
    (SELECT MAX(cs2.cs_ext_sales_price) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = ws.ws_item_sk) AS max_catalog_sale_for_item,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_item_sk = ws.ws_item_sk) AS returns_count
  FROM web_sales ws
  LEFT JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
  LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE ws.ws_ext_sales_price > 0
),
catalog_sales_extended AS (
  SELECT
    'catalog' AS channel,
    cs.cs_sold_date_sk AS date_sk,
    dd.d_year,
    cs.cs_bill_customer_sk AS cust_sk,
    c.c_customer_id,
    cs.cs_item_sk,
    i.i_product_name,
    cs.cs_quantity,
    cs.cs_ext_sales_price AS sales,
    cs.cs_net_profit AS profit,
    COALESCE(p.p_discount_active, 'N') AS promo_active,
    CASE
      WHEN cs.cs_quantity > 10 THEN 'Bulk' ELSE 'Regular'
    END AS sales_type,
    NULLIF(cs.cs_coupon_amt, 0.0) AS coupon_amount,
    (SELECT MAX(cs2.cs_ext_sales_price) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = cs.cs_item_sk) AS max_catalog_sale_for_item,
    (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_item_sk = cs.cs_item_sk) AS returns_count
  FROM catalog_sales cs
  LEFT JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
  LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cs.cs_ext_sales_price > 0
),
combined_sales AS (
  SELECT * FROM sales_by_channel
  UNION ALL
  SELECT * FROM web_sales_extended
  UNION ALL
  SELECT * FROM catalog_sales_extended
),
customer_summary AS (
  SELECT
    cust_sk,
    c_customer_id,
    channel,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    COUNT(*) AS txn_count,
    SUM(returns_count) AS total_returns,
    MIN(date_sk) AS first_sale_sk,
    MAX(date_sk) AS last_sale_sk,
    approx_percentile(sales, 0.5) AS median_sale_amount,
    array_join(array_agg(sales_type ORDER BY sales_type), ',') AS sales_type_agg,
    CASE
      WHEN SUM(profit) > 0 THEN 'Profitable'
      WHEN SUM(profit) = 0 THEN 'BreakEven'
      ELSE 'Loss'
    END AS profit_status
  FROM combined_sales
  GROUP BY GROUPING SETS ((cust_sk, c_customer_id, channel), (cust_sk, c_customer_id))
),
ranked_customers AS (
  SELECT
    cust_sk,
    c_customer_id,
    channel,
    total_sales,
    total_profit,
    txn_count,
    profit_status,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_profit DESC) AS profit_rank,
    RANK() OVER (PARTITION BY channel ORDER BY median_sale_amount DESC) AS median_sales_rank,
    NTILE(5) OVER (PARTITION BY channel ORDER BY total_sales) AS sales_quintile
  FROM customer_summary
  WHERE channel IS NOT NULL
)
SELECT
  rc.cust_sk,
  rc.c_customer_id,
  rc.channel,
  rc.total_sales,
  rc.total_profit,
  rc.txn_count,
  rc.profit_status,
  rc.profit_rank,
  rc.median_sales_rank,
  rc.sales_quintile,
  CASE
    WHEN rc.profit_rank = 1 THEN 'TopGainer'
    WHEN rc.sales_quintile = 5 THEN 'HighSpender'
    ELSE NULL
  END AS special_label,
  COALESCE(NULLIF(rc.channel, ''), 'UNKNOWN') AS normalized_channel,
  CONCAT(rc.c_customer_id, '-', rc.channel) AS composite_key,
  (SELECT COUNT(*) FROM combined_sales cs2 WHERE cs2.cust_sk = rc.cust_sk AND cs2.sales > rc.total_sales) AS higher_sales_customer_count,
  CASE
    WHEN EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_customer_sk = rc.cust_sk AND sr.sr_net_loss > 0)
      THEN 'HasStoreReturnLoss' ELSE 'NoStoreReturnLoss' END AS store_return_flag
FROM ranked_customers rc
WHERE rc.profit_rank <= 10
ORDER BY rc.channel, rc.profit_rank
