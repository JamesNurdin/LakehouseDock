/*
   Net revenue and profit per item category by month.
   Combines catalog sales, web sales and catalog returns.
   Uses only the allowed tables and join rules.
*/
WITH catalog_sales_agg AS (
    SELECT
        d1.d_year               AS d_year,
        d1.d_month_seq          AS d_month_seq,
        i.i_category            AS i_category,
        SUM(cs.cs_net_paid)    AS total_cs_net_paid,
        SUM(cs.cs_net_profit)  AS total_cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d1
      ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d1.d_year, d1.d_month_seq, i.i_category
),
web_sales_agg AS (
    SELECT
        d2.d_year               AS d_year,
        d2.d_month_seq          AS d_month_seq,
        i.i_category            AS i_category,
        SUM(ws.ws_net_paid)    AS total_ws_net_paid,
        SUM(ws.ws_net_profit)  AS total_ws_net_profit
    FROM web_sales ws
    JOIN date_dim d2
      ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d2.d_year, d2.d_month_seq, i.i_category
),
catalog_returns_agg AS (
    SELECT
        d3.d_year               AS d_year,
        d3.d_month_seq          AS d_month_seq,
        i.i_category            AS i_category,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        SUM(cr.cr_store_credit)  AS total_store_credit,
        SUM(cr.cr_fee)           AS total_fee,
        SUM(cr.cr_net_loss)      AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d3
      ON cr.cr_returned_date_sk = d3.d_date_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d3.d_year, d3.d_month_seq, i.i_category
)
SELECT
    COALESCE(cs.d_year, ws.d_year, cr.d_year)               AS sales_year,
    COALESCE(cs.d_month_seq, ws.d_month_seq, cr.d_month_seq) AS sales_month_seq,
    COALESCE(cs.i_category, ws.i_category, cr.i_category)   AS category,
    COALESCE(cs.total_cs_net_paid, 0) +
    COALESCE(ws.total_ws_net_paid, 0) -
    COALESCE(cr.total_refunded_cash, 0) -
    COALESCE(cr.total_store_credit, 0) -
    COALESCE(cr.total_fee, 0)                               AS net_revenue,
    COALESCE(cs.total_cs_net_profit, 0) +
    COALESCE(ws.total_ws_net_profit, 0) -
    COALESCE(cr.total_net_loss, 0)                         AS net_profit
FROM catalog_sales_agg cs
FULL OUTER JOIN web_sales_agg ws
  ON cs.d_year = ws.d_year
 AND cs.d_month_seq = ws.d_month_seq
 AND cs.i_category = ws.i_category
FULL OUTER JOIN catalog_returns_agg cr
  ON COALESCE(cs.d_year, ws.d_year) = cr.d_year
 AND COALESCE(cs.d_month_seq, ws.d_month_seq) = cr.d_month_seq
 AND COALESCE(cs.i_category, ws.i_category) = cr.i_category
ORDER BY sales_year, sales_month_seq, net_profit DESC
