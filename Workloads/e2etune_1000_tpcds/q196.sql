WITH
store_sales_agg AS (
  SELECT
    i.i_category,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_ext_discount_amt) AS store_discount_total,
    COUNT(*) AS store_sales_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
    AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
  GROUP BY i.i_category, d.d_year, d.d_month_seq
),
web_sales_agg AS (
  SELECT
    i.i_category,
    d.d_year,
    d.d_month_seq,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(ws.ws_ext_discount_amt) AS web_discount_total,
    COUNT(*) AS web_sales_cnt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
    AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
  GROUP BY i.i_category, d.d_year, d.d_month_seq
),
catalog_returns_agg AS (
  SELECT
    i.i_category,
    d.d_year,
    d.d_month_seq,
    SUM(cr.cr_net_loss) AS catalog_return_loss,
    SUM(cr.cr_return_quantity) AS catalog_return_qty
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_category, d.d_year, d.d_month_seq
),
web_returns_agg AS (
  SELECT
    i.i_category,
    d.d_year,
    d.d_month_seq,
    SUM(wr.wr_net_loss) AS web_return_loss,
    SUM(wr.wr_return_quantity) AS web_return_qty
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_category, d.d_year, d.d_month_seq
)
SELECT
  COALESCE(ss.i_category, ws.i_category, cr.i_category, wr.i_category) AS category,
  COALESCE(ss.d_year, ws.d_year, cr.d_year, wr.d_year) AS year,
  COALESCE(ss.d_month_seq, ws.d_month_seq, cr.d_month_seq, wr.d_month_seq) AS month_seq,
  COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) -
    COALESCE(cr.catalog_return_loss, 0) - COALESCE(wr.web_return_loss, 0) AS net_profit_adj,
  COALESCE(ss.store_discount_total, 0) + COALESCE(ws.web_discount_total, 0) AS total_discount,
  COALESCE(ss.store_sales_cnt, 0) + COALESCE(ws.web_sales_cnt, 0) AS total_sales_cnt,
  COALESCE(cr.catalog_return_qty, 0) + COALESCE(wr.web_return_qty, 0) AS total_return_qty
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
  ON ss.i_category = ws.i_category
  AND ss.d_year = ws.d_year
  AND ss.d_month_seq = ws.d_month_seq
FULL OUTER JOIN catalog_returns_agg cr
  ON COALESCE(ss.i_category, ws.i_category) = cr.i_category
  AND COALESCE(ss.d_year, ws.d_year) = cr.d_year
  AND COALESCE(ss.d_month_seq, ws.d_month_seq) = cr.d_month_seq
FULL OUTER JOIN web_returns_agg wr
  ON COALESCE(ss.i_category, ws.i_category, cr.i_category) = wr.i_category
  AND COALESCE(ss.d_year, ws.d_year, cr.d_year) = wr.d_year
  AND COALESCE(ss.d_month_seq, ws.d_month_seq, cr.d_month_seq) = wr.d_month_seq
WHERE (COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) -
       COALESCE(cr.catalog_return_loss, 0) - COALESCE(wr.web_return_loss, 0)) <> 0
ORDER BY net_profit_adj DESC
LIMIT 100
