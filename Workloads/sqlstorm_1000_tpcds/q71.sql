WITH sales AS (
  SELECT
    ss_sold_date_sk AS date_sk,
    ss_store_sk AS store_sk,
    ss_item_sk AS item_sk,
    ss_net_profit AS profit,
    'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT
    cs_sold_date_sk,
    cs_call_center_sk,
    cs_item_sk,
    cs_net_profit,
    'catalog'
  FROM catalog_sales
  UNION ALL
  SELECT
    ws_sold_date_sk,
    ws_web_page_sk,
    ws_item_sk,
    ws_net_profit,
    'web'
  FROM web_sales
),
returns AS (
  SELECT
    sr_returned_date_sk AS date_sk,
    sr_store_sk AS store_sk,
    sr_item_sk AS item_sk,
    sr_net_loss AS loss,
    'store' AS channel
  FROM store_returns
  UNION ALL
  SELECT
    cr_returned_date_sk,
    cr_call_center_sk,
    cr_item_sk,
    cr_net_loss,
    'catalog'
  FROM catalog_returns
  UNION ALL
  SELECT
    wr_returned_date_sk,
    wr_web_page_sk,
    wr_item_sk,
    wr_net_loss,
    'web'
  FROM web_returns
),
joined AS (
  SELECT
    s.channel,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    i.i_brand,
    SUM(s.profit) AS total_profit,
    COALESCE(SUM(r.loss), 0) AS total_loss,
    COUNT(*) AS sales_cnt
  FROM sales s
  LEFT JOIN returns r
    ON s.channel = r.channel
    AND s.date_sk = r.date_sk
    AND s.store_sk = r.store_sk
    AND s.item_sk = r.item_sk
  JOIN date_dim d
    ON s.date_sk = d.d_date_sk
  JOIN item i
    ON s.item_sk = i.i_item_sk
  GROUP BY
    s.channel,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    i.i_brand
),
ranked AS (
  SELECT
    channel,
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    total_profit - total_loss AS net_profit,
    sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY channel, d_year, d_month_seq ORDER BY total_profit - total_loss DESC) AS brand_rank
  FROM joined
)
SELECT
  channel,
  d_year,
  d_month_seq,
  i_category,
  i_class,
  i_brand,
  net_profit,
  sales_cnt
FROM ranked
WHERE brand_rank <= 5
ORDER BY channel, d_year, d_month_seq, net_profit DESC
