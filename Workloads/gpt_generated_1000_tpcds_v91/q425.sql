WITH
  store_sales_returns AS (
    SELECT
      COALESCE(ss.ss_ticket_number, sr.sr_ticket_number) AS ticket_number,
      COALESCE(ss.ss_item_sk, sr.sr_item_sk) AS item_sk,
      COALESCE(ss.ss_sold_date_sk, sr.sr_returned_date_sk) AS date_sk,
      COALESCE(ss.ss_net_profit, 0) AS sales_net_profit,
      COALESCE(sr.sr_net_loss, 0) AS return_net_loss
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
  ),
  store_agg AS (
    SELECT
      i.i_item_id,
      d.d_year,
      SUM(ssr.sales_net_profit - ssr.return_net_loss) AS net_contribution,
      'store' AS source
    FROM store_sales_returns ssr
    JOIN item i
      ON i.i_item_sk = ssr.item_sk
    JOIN date_dim d
      ON d.d_date_sk = ssr.date_sk
    WHERE i.i_brand = 'Brand#12'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY i.i_item_id, d.d_year
  ),
  catalog_sales_returns AS (
    SELECT
      COALESCE(cs.cs_order_number, cr.cr_order_number) AS order_number,
      COALESCE(cs.cs_item_sk, cr.cr_item_sk) AS item_sk,
      COALESCE(cs.cs_sold_date_sk, cr.cr_returned_date_sk) AS date_sk,
      COALESCE(cs.cs_net_profit, 0) AS sales_net_profit,
      COALESCE(cr.cr_net_loss, 0) AS return_net_loss
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
  ),
  catalog_agg AS (
    SELECT
      i.i_item_id,
      d.d_year,
      SUM(csrs.sales_net_profit - csrs.return_net_loss) AS net_contribution,
      'catalog' AS source
    FROM catalog_sales_returns csrs
    JOIN item i
      ON i.i_item_sk = csrs.item_sk
    JOIN date_dim d
      ON d.d_date_sk = csrs.date_sk
    WHERE i.i_category = 'Electronics'
      AND d.d_year BETWEEN 2001 AND 2003
    GROUP BY i.i_item_id, d.d_year
  )
SELECT
  i_item_id,
  d_year,
  net_contribution,
  source
FROM (
  SELECT i_item_id, d_year, net_contribution, source FROM store_agg
  UNION ALL
  SELECT i_item_id, d_year, net_contribution, source FROM catalog_agg
) AS combined
ORDER BY net_contribution DESC, d_year, i_item_id
LIMIT 100
