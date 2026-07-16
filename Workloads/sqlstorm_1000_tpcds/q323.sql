WITH
sales AS (
  SELECT
    ss.ss_sold_date_sk AS date_sk,
    d.d_year,
    d.d_month_seq,
    d.d_moy AS month,
    s.s_state AS region,
    'store' AS channel,
    i.i_category,
    i.i_class,
    i.i_brand,
    ss.ss_customer_sk AS customer_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_quantity AS quantity,
    ss.ss_ext_sales_price AS sales_amount,
    ss.ss_ext_discount_amt AS discount_amount,
    ss.ss_net_profit AS profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  UNION ALL
  SELECT
    cs.cs_sold_date_sk AS date_sk,
    d.d_year,
    d.d_month_seq,
    d.d_moy AS month,
    NULL AS region,
    'catalog' AS channel,
    i.i_category,
    i.i_class,
    i.i_brand,
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_quantity AS quantity,
    cs.cs_ext_sales_price AS sales_amount,
    cs.cs_ext_discount_amt AS discount_amount,
    cs.cs_net_profit AS profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  UNION ALL
  SELECT
    ws.ws_sold_date_sk AS date_sk,
    d.d_year,
    d.d_month_seq,
    d.d_moy AS month,
    NULL AS region,
    'web' AS channel,
    i.i_category,
    i.i_class,
    i.i_brand,
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_item_sk AS item_sk,
    ws.ws_quantity AS quantity,
    ws.ws_ext_sales_price AS sales_amount,
    ws.ws_ext_discount_amt AS discount_amount,
    ws.ws_net_profit AS profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
),
returns AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'store' AS channel,
    s.s_state AS region,
    SUM(sr.sr_net_loss) AS return_loss,
    COUNT(*) AS return_cnt
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, d.d_month_seq, s.s_state
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    'catalog' AS channel,
    NULL AS region,
    SUM(cr.cr_net_loss) AS return_loss,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, d.d_month_seq
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    'web' AS channel,
    NULL AS region,
    SUM(wr.wr_net_loss) AS return_loss,
    COUNT(*) AS return_cnt
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, d.d_month_seq
),
sales_agg AS (
  SELECT
    s.d_year,
    s.month,
    s.d_month_seq,
    s.region,
    s.channel,
    s.i_category,
    s.i_class,
    s.i_brand,
    COUNT(DISTINCT s.customer_sk) AS distinct_customers,
    SUM(s.quantity) AS total_quantity,
    SUM(s.sales_amount) AS total_sales,
    SUM(s.profit) AS total_profit,
    SUM(s.discount_amount) / NULLIF(SUM(s.sales_amount), 0) AS avg_discount_rate,
    approx_percentile(s.profit, 0.9) AS profit_90th_percentile
  FROM sales s
  GROUP BY
    s.d_year,
    s.month,
    s.d_month_seq,
    s.region,
    s.channel,
    s.i_category,
    s.i_class,
    s.i_brand
),
sales_with_returns AS (
  SELECT
    sa.*,
    COALESCE(r.return_loss, 0) AS total_return_loss,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    sa.total_profit - COALESCE(r.return_loss, 0) AS net_profit_after_returns,
    CASE WHEN sa.total_quantity > 0 THEN sa.total_profit / NULLIF(sa.total_quantity, 0) ELSE NULL END AS profit_per_unit
  FROM sales_agg sa
  LEFT JOIN returns r
    ON sa.d_year = r.d_year
   AND sa.d_month_seq = r.d_month_seq
   AND sa.channel = r.channel
   AND (sa.channel <> 'store' OR sa.region = r.region)
),
final AS (
  SELECT
    d_year,
    month,
    region,
    channel,
    i_category,
    i_class,
    i_brand,
    distinct_customers,
    total_quantity,
    total_sales,
    total_profit,
    total_return_loss,
    net_profit_after_returns,
    profit_per_unit,
    avg_discount_rate,
    profit_90th_percentile,
    return_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year, month, channel ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER (PARTITION BY channel ORDER BY d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_channel
  FROM sales_with_returns
)
SELECT *
FROM final
WHERE total_sales > 100000
ORDER BY d_year, month, channel, total_profit DESC
