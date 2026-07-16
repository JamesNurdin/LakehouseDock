WITH store_sales_agg AS (
   SELECT
       'store' AS channel,
       d.d_year,
       i.i_category,
       cd.cd_gender AS gender,
       SUM(ss.ss_net_profit) AS net_profit_sales,
       SUM(ss.ss_net_paid) AS net_paid_sales,
       SUM(ss.ss_quantity) AS quantity_sales,
       COUNT(DISTINCT ss.ss_ticket_number) AS orders_sales,
       0 AS net_loss_returns,
       0 AS return_amount,
       0 AS return_quantity
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY d.d_year, i.i_category, cd.cd_gender
),
store_returns_agg AS (
   SELECT
       d.d_year,
       i.i_category,
       cd.cd_gender AS gender,
       SUM(sr.sr_net_loss) AS net_loss_returns,
       SUM(sr.sr_return_amt) AS return_amount,
       SUM(sr.sr_return_quantity) AS return_quantity
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY d.d_year, i.i_category, cd.cd_gender
),
catalog_sales_agg AS (
   SELECT
       'catalog' AS channel,
       d.d_year,
       i.i_category,
       cd.cd_gender AS gender,
       SUM(cs.cs_net_profit) AS net_profit_sales,
       SUM(cs.cs_net_paid) AS net_paid_sales,
       SUM(cs.cs_quantity) AS quantity_sales,
       COUNT(DISTINCT cs.cs_order_number) AS orders_sales,
       0 AS net_loss_returns,
       0 AS return_amount,
       0 AS return_quantity
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY d.d_year, i.i_category, cd.cd_gender
),
catalog_returns_agg AS (
   SELECT
       d.d_year,
       i.i_category,
       cd.cd_gender AS gender,
       SUM(cr.cr_net_loss) AS net_loss_returns,
       SUM(cr.cr_return_amount) AS return_amount,
       SUM(cr.cr_return_quantity) AS return_quantity
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY d.d_year, i.i_category, cd.cd_gender
),
web_sales_agg AS (
   SELECT
       'web' AS channel,
       d.d_year,
       i.i_category,
       cd.cd_gender AS gender,
       SUM(ws.ws_net_profit) AS net_profit_sales,
       SUM(ws.ws_net_paid) AS net_paid_sales,
       SUM(ws.ws_quantity) AS quantity_sales,
       COUNT(DISTINCT ws.ws_order_number) AS orders_sales,
       0 AS net_loss_returns,
       0 AS return_amount,
       0 AS return_quantity
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY d.d_year, i.i_category, cd.cd_gender
),
web_returns_agg AS (
   SELECT
       d.d_year,
       i.i_category,
       cd.cd_gender AS gender,
       SUM(wr.wr_net_loss) AS net_loss_returns,
       SUM(wr.wr_return_amt) AS return_amount,
       SUM(wr.wr_return_quantity) AS return_quantity
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY d.d_year, i.i_category, cd.cd_gender
),
combined_store AS (
   SELECT
       'store' AS channel,
       s.d_year,
       s.i_category,
       s.gender,
       s.net_profit_sales,
       s.net_paid_sales,
       s.quantity_sales,
       s.orders_sales,
       COALESCE(r.net_loss_returns, 0) AS net_loss_returns,
       COALESCE(r.return_amount, 0) AS return_amount,
       COALESCE(r.return_quantity, 0) AS return_quantity
   FROM store_sales_agg s
   LEFT JOIN store_returns_agg r
     ON s.d_year = r.d_year
    AND s.i_category = r.i_category
    AND s.gender = r.gender
),
combined_catalog AS (
   SELECT
       'catalog' AS channel,
       s.d_year,
       s.i_category,
       s.gender,
       s.net_profit_sales,
       s.net_paid_sales,
       s.quantity_sales,
       s.orders_sales,
       COALESCE(r.net_loss_returns, 0) AS net_loss_returns,
       COALESCE(r.return_amount, 0) AS return_amount,
       COALESCE(r.return_quantity, 0) AS return_quantity
   FROM catalog_sales_agg s
   LEFT JOIN catalog_returns_agg r
     ON s.d_year = r.d_year
    AND s.i_category = r.i_category
    AND s.gender = r.gender
),
combined_web AS (
   SELECT
       'web' AS channel,
       s.d_year,
       s.i_category,
       s.gender,
       s.net_profit_sales,
       s.net_paid_sales,
       s.quantity_sales,
       s.orders_sales,
       COALESCE(r.net_loss_returns, 0) AS net_loss_returns,
       COALESCE(r.return_amount, 0) AS return_amount,
       COALESCE(r.return_quantity, 0) AS return_quantity
   FROM web_sales_agg s
   LEFT JOIN web_returns_agg r
     ON s.d_year = r.d_year
    AND s.i_category = r.i_category
    AND s.gender = r.gender
),
all_combined AS (
   SELECT * FROM combined_store
   UNION ALL
   SELECT * FROM combined_catalog
   UNION ALL
   SELECT * FROM combined_web
),
final AS (
   SELECT
       channel,
       d_year,
       i_category,
       gender,
       net_profit_sales,
       net_paid_sales,
       quantity_sales,
       orders_sales,
       net_loss_returns,
       return_amount,
       return_quantity,
       (net_profit_sales - net_loss_returns) AS net_profit_adj,
       (net_paid_sales - return_amount) AS net_paid_adj,
       CASE WHEN net_paid_sales <> 0 THEN ((net_profit_sales - net_loss_returns) / net_paid_sales) * 100 ELSE NULL END AS profit_margin_adj_percent,
       ROW_NUMBER() OVER (PARTITION BY channel, d_year ORDER BY (net_profit_sales - net_loss_returns) DESC) AS rank_by_profit
   FROM all_combined
)
SELECT *
FROM final
WHERE rank_by_profit <= 10
ORDER BY channel, d_year, rank_by_profit
