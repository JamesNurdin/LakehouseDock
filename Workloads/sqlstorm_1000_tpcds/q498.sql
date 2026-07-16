WITH sales AS (
  SELECT
    ss_sold_date_sk AS sold_date_sk,
    ss_item_sk AS item_sk,
    ss_store_sk AS store_sk,
    NULL AS call_center_sk,
    ss_promo_sk AS promo_sk,
    ss_quantity AS quantity,
    ss_ext_sales_price AS sales_amount,
    ss_net_paid AS net_paid,
    ss_net_profit AS profit,
    ss_ext_discount_amt AS discount_amt,
    'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT
    cs_sold_date_sk,
    cs_item_sk,
    NULL,
    cs_call_center_sk,
    cs_promo_sk,
    cs_quantity,
    cs_ext_sales_price,
    cs_net_paid,
    cs_net_profit,
    cs_ext_discount_amt,
    'catalog'
  FROM catalog_sales
  UNION ALL
  SELECT
    ws_sold_date_sk,
    ws_item_sk,
    NULL,
    NULL,
    ws_promo_sk,
    ws_quantity,
    ws_ext_sales_price,
    ws_net_paid,
    ws_net_profit,
    ws_ext_discount_amt,
    'web'
  FROM web_sales
), returns AS (
  SELECT
    sr_returned_date_sk AS returned_date_sk,
    sr_item_sk AS item_sk,
    sr_store_sk AS store_sk,
    NULL AS call_center_sk,
    NULL AS promo_sk,
    sr_return_quantity AS quantity,
    sr_return_amt AS return_amount,
    sr_net_loss AS net_loss,
    'store' AS channel
  FROM store_returns
  UNION ALL
  SELECT
    cr_returned_date_sk,
    cr_item_sk,
    NULL,
    cr_call_center_sk,
    NULL,
    cr_return_quantity,
    cr_return_amount,
    cr_net_loss,
    'catalog'
  FROM catalog_returns
  UNION ALL
  SELECT
    wr_returned_date_sk,
    wr_item_sk,
    NULL,
    NULL,
    NULL,
    wr_return_quantity,
    wr_return_amt,
    wr_net_loss,
    'web'
  FROM web_returns
), sales_enriched AS (
  SELECT
    s.sold_date_sk,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    COALESCE(p.p_promo_id, 'NO_PROMO') AS promo_flag,
    s.channel,
    s.quantity,
    s.sales_amount,
    s.net_paid,
    s.profit,
    s.discount_amt,
    s.item_sk,
    s.store_sk,
    s.call_center_sk
  FROM sales s
  LEFT JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
  LEFT JOIN item i ON s.item_sk = i.i_item_sk
  LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
), returns_enriched AS (
  SELECT
    r.returned_date_sk,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    COALESCE(p.p_promo_id, 'NO_PROMO') AS promo_flag,
    r.channel,
    r.quantity,
    r.return_amount,
    r.net_loss,
    r.item_sk,
    r.store_sk,
    r.call_center_sk
  FROM returns r
  LEFT JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
  LEFT JOIN item i ON r.item_sk = i.i_item_sk
  LEFT JOIN promotion p ON r.promo_sk = p.p_promo_sk
), agg AS (
  SELECT
    se.d_year,
    se.d_month_seq,
    se.i_category,
    se.promo_flag,
    se.channel,
    SUM(se.sales_amount) AS total_sales_amount,
    SUM(se.net_paid) AS total_net_paid,
    SUM(se.profit) AS total_profit,
    SUM(se.discount_amt) AS total_discount,
    SUM(se.quantity) AS total_quantity,
    APPROX_DISTINCT(se.item_sk) AS distinct_items_sold,
    APPROX_DISTINCT(se.store_sk) AS distinct_stores,
    APPROX_DISTINCT(se.call_center_sk) AS distinct_call_centers
  FROM sales_enriched se
  GROUP BY
    se.d_year,
    se.d_month_seq,
    se.i_category,
    se.promo_flag,
    se.channel
), agg_returns AS (
  SELECT
    re.d_year,
    re.d_month_seq,
    re.i_category,
    re.promo_flag,
    re.channel,
    SUM(re.return_amount) AS total_return_amount,
    SUM(re.net_loss) AS total_return_loss,
    SUM(re.quantity) AS total_return_quantity,
    APPROX_DISTINCT(re.item_sk) AS distinct_items_returned
  FROM returns_enriched re
  GROUP BY
    re.d_year,
    re.d_month_seq,
    re.i_category,
    re.promo_flag,
    re.channel
)
SELECT
  a.d_year,
  a.d_month_seq,
  a.i_category,
  a.promo_flag,
  a.channel,
  a.total_sales_amount,
  a.total_net_paid,
  a.total_profit,
  a.total_discount,
  a.total_quantity,
  a.distinct_items_sold,
  a.distinct_stores,
  a.distinct_call_centers,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
  COALESCE(r.distinct_items_returned, 0) AS distinct_items_returned,
  CASE WHEN a.total_sales_amount > 0 THEN COALESCE(r.total_return_amount, 0) / a.total_sales_amount ELSE 0 END AS return_rate,
  ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales_amount DESC) AS category_rank_in_year
FROM agg a
LEFT JOIN agg_returns r
  ON a.d_year = r.d_year
 AND a.d_month_seq = r.d_month_seq
 AND a.i_category = r.i_category
 AND a.promo_flag = r.promo_flag
 AND a.channel = r.channel
WHERE a.d_year BETWEEN 1998 AND 2002
ORDER BY a.d_year, a.total_sales_amount DESC
LIMIT 100
