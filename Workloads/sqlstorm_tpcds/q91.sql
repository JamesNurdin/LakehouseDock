WITH
store_sales_cte AS (
  SELECT
    ss.ss_sold_date_sk AS date_sk,
    d.d_date,
    'store' AS channel,
    ss.ss_item_sk AS item_sk,
    ss.ss_ticket_number AS ticket_number,
    ss.ss_quantity AS quantity,
    ss.ss_ext_sales_price AS ext_sales_price,
    ss.ss_ext_discount_amt AS ext_discount,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    ss.ss_promo_sk AS promo_sk,
    i.i_product_name
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
catalog_sales_cte AS (
  SELECT
    cs.cs_sold_date_sk AS date_sk,
    d.d_date,
    'catalog' AS channel,
    cs.cs_item_sk AS item_sk,
    cs.cs_order_number AS ticket_number,
    cs.cs_quantity AS quantity,
    cs.cs_ext_sales_price AS ext_sales_price,
    cs.cs_ext_discount_amt AS ext_discount,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    cs.cs_promo_sk AS promo_sk,
    i.i_product_name
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
web_sales_cte AS (
  SELECT
    ws.ws_sold_date_sk AS date_sk,
    d.d_date,
    'web' AS channel,
    ws.ws_item_sk AS item_sk,
    ws.ws_order_number AS ticket_number,
    ws.ws_quantity AS quantity,
    ws.ws_ext_sales_price AS ext_sales_price,
    ws.ws_ext_discount_amt AS ext_discount,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    ws.ws_promo_sk AS promo_sk,
    i.i_product_name
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
sales_union AS (
  SELECT * FROM store_sales_cte
  UNION ALL
  SELECT * FROM catalog_sales_cte
  UNION ALL
  SELECT * FROM web_sales_cte
),
returns_union AS (
  SELECT
    sr.sr_returned_date_sk AS date_sk,
    d.d_date,
    'store' AS channel,
    sr.sr_item_sk AS item_sk,
    sr.sr_ticket_number AS ticket_number,
    sr.sr_return_quantity AS return_quantity,
    sr.sr_return_amt AS return_amount,
    sr.sr_net_loss AS net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  UNION ALL
  SELECT
    cr.cr_returned_date_sk AS date_sk,
    d.d_date,
    'catalog' AS channel,
    cr.cr_item_sk AS item_sk,
    cr.cr_order_number AS ticket_number,
    cr.cr_return_quantity AS return_quantity,
    cr.cr_return_amount AS return_amount,
    cr.cr_net_loss AS net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  UNION ALL
  SELECT
    wr.wr_returned_date_sk AS date_sk,
    d.d_date,
    'web' AS channel,
    wr.wr_item_sk AS item_sk,
    wr.wr_order_number AS ticket_number,
    wr.wr_return_quantity AS return_quantity,
    wr.wr_return_amt AS return_amount,
    wr.wr_net_loss AS net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),
sales_returns_join AS (
  SELECT
    s.channel,
    s.date_sk,
    s.d_date,
    s.item_sk,
    s.ticket_number,
    s.quantity,
    s.ext_sales_price,
    s.ext_discount,
    s.net_paid,
    s.net_profit,
    s.promo_sk,
    s.i_product_name,
    COALESCE(r.return_quantity, 0) AS returned_quantity,
    COALESCE(r.return_amount, 0) AS returned_amount,
    COALESCE(r.net_loss, 0) AS returned_net_loss,
    s.net_paid - COALESCE(r.return_amount, 0) AS net_paid_adj,
    s.net_profit - COALESCE(r.net_loss, 0) AS net_profit_adj,
    CASE WHEN s.ext_sales_price > 0 THEN s.ext_discount / s.ext_sales_price ELSE 0 END AS discount_ratio,
    CASE WHEN (s.net_profit - COALESCE(r.net_loss, 0)) > 1000 THEN 1 ELSE 0 END AS high_profit_flag
  FROM sales_union s
  LEFT JOIN returns_union r
    ON s.channel = r.channel
    AND s.date_sk = r.date_sk
    AND s.item_sk = r.item_sk
    AND s.ticket_number = r.ticket_number
),
aggregated_base AS (
  SELECT
    channel,
    d_date,
    COUNT(DISTINCT ticket_number) AS total_transactions,
    SUM(quantity) AS total_quantity_sold,
    SUM(returned_quantity) AS total_quantity_returned,
    SUM(ext_sales_price) AS total_sales,
    SUM(returned_amount) AS total_returns,
    SUM(net_paid_adj) AS total_net_paid,
    SUM(net_profit_adj) AS total_net_profit,
    AVG(discount_ratio) AS avg_discount_ratio,
    SUM(high_profit_flag) AS high_profit_items
  FROM sales_returns_join
  GROUP BY channel, d_date
),
aggregated AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY total_net_profit DESC) AS profit_rank
  FROM aggregated_base
),
top_items AS (
  SELECT
    s.channel,
    s.d_date,
    s.item_sk,
    s.i_product_name,
    SUM(s.net_profit_adj) AS item_net_profit,
    RANK() OVER (PARTITION BY s.channel, s.d_date ORDER BY SUM(s.net_profit_adj) DESC) AS item_rank
  FROM sales_returns_join s
  GROUP BY s.channel, s.d_date, s.item_sk, s.i_product_name
  HAVING SUM(s.net_profit_adj) > 0
)
SELECT
  a.channel,
  a.d_date,
  a.total_transactions,
  a.total_quantity_sold,
  a.total_quantity_returned,
  a.total_sales,
  a.total_returns,
  a.total_net_paid,
  a.total_net_profit,
  ROUND(a.avg_discount_ratio, 4) AS avg_discount_ratio,
  a.high_profit_items,
  a.profit_rank,
  ti.item_sk,
  COALESCE(ti.i_product_name, 'UNKNOWN') AS product_name,
  ti.item_net_profit,
  ti.item_rank,
  CONCAT(a.channel, '-', CAST(ti.item_sk AS VARCHAR)) AS channel_item_key,
  (SELECT AVG(s2.net_profit_adj) FROM sales_returns_join s2 WHERE s2.item_sk = ti.item_sk) AS overall_item_avg_profit
FROM aggregated a
LEFT JOIN (
  SELECT *
  FROM top_items
  WHERE item_rank <= 5
) ti
  ON a.channel = ti.channel
  AND a.d_date = ti.d_date
WHERE a.d_date >= DATE '2001-01-01' AND a.d_date < DATE '2001-02-01'
ORDER BY a.d_date, a.profit_rank, ti.item_rank
