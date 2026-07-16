WITH sales_agg AS (
   SELECT
       ws.ws_item_sk,
       ws.ws_sold_date_sk,
       i.i_category,
       i.i_class,
       SUM(ws.ws_net_paid) AS total_sales,
       SUM(ws.ws_quantity) AS total_units_sold,
       SUM(ws.ws_net_profit) AS total_profit,
       MIN(t.t_hour) AS earliest_sale_hour,
       MAX(t.t_hour) AS latest_sale_hour
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2450806 AND 2451063
     AND i.i_category = 'Electronics'
   GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk, i.i_category, i.i_class
),
returns_agg AS (
   SELECT
       sr.sr_item_sk,
       sr.sr_returned_date_sk,
       i.i_category,
       i.i_class,
       SUM(sr.sr_return_quantity) AS total_returns,
       SUM(sr.sr_refunded_cash) AS total_refunded,
       SUM(sr.sr_net_loss) AS total_loss
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   WHERE sr.sr_returned_date_sk BETWEEN 2450806 AND 2451063
     AND i.i_category = 'Electronics'
   GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk, i.i_category, i.i_class
),
inv_agg AS (
   SELECT
       inv.inv_item_sk,
       i.i_category,
       i.i_class,
       AVG(inv.inv_quantity_on_hand) AS avg_on_hand
   FROM inventory inv
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   WHERE inv.inv_date_sk BETWEEN 2450806 AND 2451063
   GROUP BY inv.inv_item_sk, i.i_category, i.i_class
)
SELECT
    s.i_category,
    s.i_class,
    s.ws_sold_date_sk AS sales_date,
    s.total_sales,
    s.total_units_sold,
    s.total_profit,
    s.earliest_sale_hour,
    s.latest_sale_hour,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_refunded, 0) AS total_refunded,
    COALESCE(r.total_loss, 0) AS total_loss,
    inv.avg_on_hand,
    (s.total_sales - COALESCE(r.total_loss, 0)) / NULLIF(s.total_units_sold, 0) AS net_sales_per_unit,
    ROW_NUMBER() OVER (PARTITION BY s.i_category ORDER BY s.total_sales DESC) AS sales_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ws_item_sk = r.sr_item_sk
   AND s.ws_sold_date_sk = r.sr_returned_date_sk
LEFT JOIN inv_agg inv
    ON s.ws_item_sk = inv.inv_item_sk
WHERE s.total_sales > 10000
ORDER BY s.total_sales DESC
LIMIT 100
