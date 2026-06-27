WITH catalog_sales_agg AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       i.i_category,
       SUM(cs.cs_net_profit)               AS catalog_net_profit,
       SUM(cs.cs_ext_discount_amt)         AS catalog_total_discount,
       COUNT(*)                            AS catalog_orders
   FROM catalog_sales cs
   JOIN date_dim d      ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i          ON cs.cs_item_sk      = i.i_item_sk
   GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_returns_agg AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       i.i_category,
       SUM(cr.cr_net_loss)                 AS catalog_return_loss,
       COUNT(*)                            AS catalog_return_orders
   FROM catalog_returns cr
   JOIN date_dim d      ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i          ON cr.cr_item_sk          = i.i_item_sk
   GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_sales_agg AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       i.i_category,
       SUM(ws.ws_net_profit)               AS web_net_profit,
       SUM(ws.ws_ext_discount_amt)         AS web_total_discount,
       COUNT(*)                            AS web_orders
   FROM web_sales ws
   JOIN date_dim d      ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i          ON ws.ws_item_sk      = i.i_item_sk
   GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_returns_agg AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       i.i_category,
       SUM(wr.wr_net_loss)                 AS web_return_loss,
       COUNT(*)                            AS web_return_orders
   FROM web_returns wr
   JOIN date_dim d      ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i          ON wr.wr_item_sk          = i.i_item_sk
   GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
   COALESCE(cs.d_year, cr.d_year, ws.d_year, wr.d_year)                 AS year,
   COALESCE(cs.d_month_seq, cr.d_month_seq, ws.d_month_seq, wr.d_month_seq) AS month_seq,
   COALESCE(cs.i_category, cr.i_category, ws.i_category, wr.i_category) AS category,
   (cs.catalog_net_profit - cr.catalog_return_loss)                  AS net_profit_catalog,
   (ws.web_net_profit - wr.web_return_loss)                         AS net_profit_web,
   ((cs.catalog_net_profit - cr.catalog_return_loss) +
    (ws.web_net_profit - wr.web_return_loss))                        AS total_net_profit,
   (cs.catalog_total_discount + ws.web_total_discount)               AS total_discount,
   (cs.catalog_orders + ws.web_orders)                               AS total_orders,
   (cr.catalog_return_orders + wr.web_return_orders)                AS total_returns
FROM catalog_sales_agg   cs
FULL OUTER JOIN catalog_returns_agg cr
   ON cs.d_year = cr.d_year
  AND cs.d_month_seq = cr.d_month_seq
  AND cs.i_category = cr.i_category
FULL OUTER JOIN web_sales_agg ws
   ON COALESCE(cs.d_year, cr.d_year) = ws.d_year
  AND COALESCE(cs.d_month_seq, cr.d_month_seq) = ws.d_month_seq
  AND COALESCE(cs.i_category, cr.i_category) = ws.i_category
FULL OUTER JOIN web_returns_agg wr
   ON COALESCE(cs.d_year, cr.d_year, ws.d_year) = wr.d_year
  AND COALESCE(cs.d_month_seq, cr.d_month_seq, ws.d_month_seq) = wr.d_month_seq
  AND COALESCE(cs.i_category, cr.i_category, ws.i_category) = wr.i_category
ORDER BY year, month_seq, category
