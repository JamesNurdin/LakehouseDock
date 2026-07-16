WITH events AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_bill_cdemo_sk AS demo_sk,
           cs_item_sk AS item_sk,
           cs_quantity AS quantity,
           cs_sales_price * cs_quantity AS amount,
           cs_ext_discount_amt AS discount,
           cs_net_profit AS profit,
           'Catalog' AS channel,
           'sale' AS event_type
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_cdemo_sk,
           ss_item_sk,
           ss_quantity,
           ss_sales_price * ss_quantity,
           ss_ext_discount_amt,
           ss_net_profit,
           'Store',
           'sale'
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_bill_cdemo_sk,
           ws_item_sk,
           ws_quantity,
           ws_sales_price * ws_quantity,
           ws_ext_discount_amt,
           ws_net_profit,
           'Web',
           'sale'
    FROM web_sales
    UNION ALL
    SELECT cr_returned_date_sk,
           cr_refunded_cdemo_sk,
           cr_item_sk,
           -cr_return_quantity,
           -cr_return_amount,
           0,
           -cr_net_loss,
           'Catalog',
           'return'
    FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk,
           sr_cdemo_sk,
           sr_item_sk,
           -sr_return_quantity,
           -sr_return_amt,
           0,
           -sr_net_loss,
           'Store',
           'return'
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk,
           wr_refunded_cdemo_sk,
           wr_item_sk,
           -wr_return_quantity,
           -wr_return_amt,
           0,
           -wr_net_loss,
           'Web',
           'return'
    FROM web_returns
),
agg AS (
    SELECT d.d_year,
           d.d_month_seq AS month_num,
           e.channel,
           i.i_category,
           cd.cd_gender,
           cd.cd_marital_status,
           sum(e.amount) AS total_amount,
           sum(e.profit) AS total_profit,
           sum(e.discount) AS total_discount,
           sum(e.quantity) AS total_quantity,
           sum(CASE WHEN e.event_type = 'sale' THEN 1 ELSE 0 END) AS sale_events,
           sum(CASE WHEN e.event_type = 'return' THEN 1 ELSE 0 END) AS return_events,
           approx_percentile(e.amount, 0.5) AS median_amount,
           sum(e.amount) / nullif(count(DISTINCT e.item_sk), 0) AS avg_amount_per_item
    FROM events e
    JOIN date_dim d ON e.date_sk = d.d_date_sk
    JOIN customer_demographics cd ON e.demo_sk = cd.cd_demo_sk
    JOIN item i ON e.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
      AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY d.d_year,
             d.d_month_seq,
             e.channel,
             i.i_category,
             cd.cd_gender,
             cd.cd_marital_status
)
SELECT a.*,
       row_number() OVER (PARTITION BY a.channel ORDER BY a.total_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.d_year, a.month_num, a.channel, a.i_category, a.cd_gender, a.cd_marital_status
LIMIT 200
