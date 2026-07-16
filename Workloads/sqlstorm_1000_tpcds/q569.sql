WITH
sales_catalog AS (
  SELECT
    d.d_year AS sale_year,
    d.d_month_seq AS sale_month,
    i.i_item_sk,
    i.i_product_name,
    i.i_item_id,
    'Catalog' AS channel,
    COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_sales,
    COALESCE(SUM(cs.cs_net_profit), 0) AS total_profit,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
    MIN(cs.cs_sold_date_sk) AS min_sold_date,
    MAX(cs.cs_sold_date_sk) AS max_sold_date,
    COALESCE((
        SELECT AVG(cr.cr_return_amount)
        FROM catalog_returns cr
        JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
        WHERE cr.cr_item_sk = i.i_item_sk
          AND dr.d_year = d.d_year
          AND dr.d_month_seq = d.d_month_seq
    ), 0) AS avg_return_amount
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name, i.i_item_id
),
sales_store AS (
  SELECT
    d.d_year AS sale_year,
    d.d_month_seq AS sale_month,
    i.i_item_sk,
    i.i_product_name,
    i.i_item_id,
    'Store' AS channel,
    COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales,
    COALESCE(SUM(ss.ss_net_profit), 0) AS total_profit,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    MIN(ss.ss_sold_date_sk) AS min_sold_date,
    MAX(ss.ss_sold_date_sk) AS max_sold_date,
    COALESCE((
        SELECT AVG(sr.sr_return_amt)
        FROM store_returns sr
        JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
        WHERE sr.sr_item_sk = i.i_item_sk
          AND dr.d_year = d.d_year
          AND dr.d_month_seq = d.d_month_seq
    ), 0) AS avg_return_amount
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name, i.i_item_id
),
sales_web AS (
  SELECT
    d.d_year AS sale_year,
    d.d_month_seq AS sale_month,
    i.i_item_sk,
    i.i_product_name,
    i.i_item_id,
    'Web' AS channel,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
    MIN(ws.ws_sold_date_sk) AS min_sold_date,
    MAX(ws.ws_sold_date_sk) AS max_sold_date,
    COALESCE((
        SELECT AVG(wr.wr_return_amt)
        FROM web_returns wr
        JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
        WHERE wr.wr_item_sk = i.i_item_sk
          AND dr.d_year = d.d_year
          AND dr.d_month_seq = d.d_month_seq
    ), 0) AS avg_return_amount
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name, i.i_item_id
),
combined AS (
  SELECT * FROM sales_catalog
  UNION ALL
  SELECT * FROM sales_store
  UNION ALL
  SELECT * FROM sales_web
),
ranked AS (
  SELECT
    c.*,
    ROW_NUMBER() OVER (PARTITION BY c.channel, c.sale_year, c.sale_month ORDER BY c.total_sales DESC) AS sales_rank,
    SUM(c.total_sales) OVER (PARTITION BY c.channel, c.sale_year) AS channel_year_sales,
    CASE
      WHEN c.total_profit / NULLIF(c.total_sales, 0) > 0.2 THEN 'High'
      WHEN c.total_profit / NULLIF(c.total_sales, 0) > 0.1 THEN 'Medium'
      ELSE 'Low'
    END AS profit_category,
    CONCAT(
      COALESCE(c.i_product_name, 'UNKNOWN'),
      ' (',
      COALESCE(c.i_item_id, '???'),
      ') - ',
      c.channel
    ) AS description
  FROM combined c
),
final AS (
  SELECT
    r.sale_year,
    r.sale_month,
    r.i_item_sk,
    r.description,
    r.channel,
    r.total_sales,
    r.total_profit,
    r.distinct_customers,
    r.avg_return_amount,
    r.sales_rank,
    r.channel_year_sales,
    r.profit_category
  FROM ranked r
  WHERE r.sales_rank = 1
    AND NOT EXISTS (
      SELECT 1
      FROM store_returns sr2
      WHERE sr2.sr_item_sk = r.i_item_sk
        AND sr2.sr_returned_date_sk = r.min_sold_date
        AND sr2.sr_net_loss > 0
    )
)
SELECT *
FROM final
ORDER BY sale_year, sale_month, channel
