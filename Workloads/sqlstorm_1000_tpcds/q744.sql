WITH sales_store AS (
  SELECT
    ss.ss_sold_date_sk AS date_sk,
    d.d_date AS sale_date,
    ss.ss_item_sk AS item_sk,
    ss.ss_customer_sk AS customer_sk,
    ss.ss_store_sk AS location_sk,
    ss.ss_ticket_number AS ticket_number,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    concat_ws(' ', COALESCE(c.c_first_name, ''), COALESCE(c.c_last_name, '')) AS customer_name,
    cd.cd_gender AS gender,
    ss.ss_net_profit / nullif(ss.ss_net_paid, 0) AS profit_margin,
    ss.ss_net_paid - COALESCE(sr.sr_net_loss, 0) AS net_paid_after_returns,
    'store' AS channel
  FROM store_sales ss
  LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_sold_date_sk = sr.sr_returned_date_sk
),
sales_web AS (
  SELECT
    ws.ws_sold_date_sk AS date_sk,
    d.d_date AS sale_date,
    ws.ws_item_sk AS item_sk,
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_web_page_sk AS location_sk,
    ws.ws_order_number AS ticket_number,
    ws.ws_quantity AS quantity,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    concat_ws(' ', COALESCE(c.c_first_name, ''), COALESCE(c.c_last_name, '')) AS customer_name,
    cd.cd_gender AS gender,
    ws.ws_net_profit / nullif(ws.ws_net_paid, 0) AS profit_margin,
    ws.ws_net_paid - COALESCE(wr.wr_net_loss, 0) AS net_paid_after_returns,
    'web' AS channel
  FROM web_sales ws
  LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_sold_date_sk = wr.wr_returned_date_sk
),
sales_catalog AS (
  SELECT
    cs.cs_sold_date_sk AS date_sk,
    d.d_date AS sale_date,
    cs.cs_item_sk AS item_sk,
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_call_center_sk AS location_sk,
    cs.cs_order_number AS ticket_number,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    concat_ws(' ', COALESCE(c.c_first_name, ''), COALESCE(c.c_last_name, '')) AS customer_name,
    cd.cd_gender AS gender,
    cs.cs_net_profit / nullif(cs.cs_net_paid, 0) AS profit_margin,
    cs.cs_net_paid - COALESCE(cr.cr_net_loss, 0) AS net_paid_after_returns,
    'catalog' AS channel
  FROM catalog_sales cs
  LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_sold_date_sk = cr.cr_returned_date_sk
),
combined_sales AS (
  SELECT * FROM sales_store
  UNION ALL
  SELECT * FROM sales_web
  UNION ALL
  SELECT * FROM sales_catalog
),
store_customers AS (SELECT DISTINCT customer_sk FROM sales_store),
web_customers AS (SELECT DISTINCT customer_sk FROM sales_web),
catalog_customers AS (SELECT DISTINCT customer_sk FROM sales_catalog),
customers_in_store_and_web AS (
  SELECT customer_sk FROM store_customers INTERSECT SELECT customer_sk FROM web_customers
),
customers_in_store_not_catalog AS (
  SELECT customer_sk FROM store_customers EXCEPT SELECT customer_sk FROM catalog_customers
),
customer_totals AS (
  SELECT
    channel,
    customer_sk,
    customer_name,
    gender,
    SUM(net_paid_after_returns) AS total_net_paid
  FROM combined_sales
  GROUP BY channel, customer_sk, customer_name, gender
),
top_customers AS (
  SELECT
    channel,
    customer_sk,
    customer_name,
    gender,
    total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_net_paid DESC) AS rank_in_channel
  FROM customer_totals
),
customer_multi_channel AS (
  SELECT
    tc.channel,
    tc.customer_sk,
    tc.customer_name,
    tc.gender,
    tc.total_net_paid,
    tc.rank_in_channel,
    CASE WHEN ciscw.customer_sk IS NOT NULL THEN 1 ELSE 0 END AS in_store_and_web,
    CASE WHEN csinc.customer_sk IS NOT NULL THEN 1 ELSE 0 END AS in_store_not_catalog
  FROM top_customers tc
  LEFT JOIN customers_in_store_and_web ciscw
    ON tc.customer_sk = ciscw.customer_sk
  LEFT JOIN customers_in_store_not_catalog csinc
    ON tc.customer_sk = csinc.customer_sk
),
rolling_sales AS (
  SELECT
    channel,
    sale_date,
    SUM(net_paid_after_returns) OVER (PARTITION BY channel ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_net_paid,
    SUM(net_paid_after_returns) OVER (PARTITION BY channel ORDER BY sale_date ROWS UNBOUNDED PRECEDING) AS cumulative_net_paid
  FROM combined_sales
  WHERE sale_date IS NOT NULL
),
high_rolling_dates AS (
  SELECT channel, sale_date, rolling_7day_net_paid
  FROM rolling_sales
  WHERE rolling_7day_net_paid > 500000
  UNION
  SELECT channel, sale_date, rolling_7day_net_paid
  FROM rolling_sales
  WHERE rolling_7day_net_paid > 800000
),
final AS (
  SELECT
    cmc.channel,
    cmc.customer_name,
    cmc.gender,
    cmc.total_net_paid,
    cmc.rank_in_channel,
    cmc.in_store_and_web,
    cmc.in_store_not_catalog,
    COALESCE((SELECT SUM(sr.sr_net_loss) FROM store_returns sr WHERE sr.sr_customer_sk = cmc.customer_sk),0) +
    COALESCE((SELECT SUM(wr.wr_net_loss) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = cmc.customer_sk),0) +
    COALESCE((SELECT SUM(cr.cr_net_loss) FROM catalog_returns cr WHERE cr.cr_refunded_customer_sk = cmc.customer_sk),0) AS total_return_loss,
    (SELECT MAX(cs.sale_date)
     FROM combined_sales cs
     WHERE cs.channel = cmc.channel
       AND cs.customer_sk = cmc.customer_sk) AS most_recent_sale_date,
    hr.sale_date AS high_rolling_date,
    hr.rolling_7day_net_paid,
    CASE
      WHEN hr.rolling_7day_net_paid > 800000 THEN 'HIGH'
      WHEN hr.rolling_7day_net_paid > 500000 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS rolling_category,
    SUM(cmc.total_net_paid) OVER (PARTITION BY cmc.channel ORDER BY cmc.rank_in_channel
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_net_paid
  FROM customer_multi_channel cmc
  LEFT JOIN high_rolling_dates hr
    ON cmc.channel = hr.channel
)
SELECT *
FROM final
WHERE rank_in_channel <= 10
ORDER BY channel, rank_in_channel
LIMIT 100
