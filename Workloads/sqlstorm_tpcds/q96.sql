WITH sales AS (
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_item_sk AS item_sk,
           cs_quantity AS quantity,
           cs_ext_sales_price AS ext_sales_price,
           cs_ext_discount_amt AS ext_discount_amt,
           cs_ext_tax AS ext_tax,
           cs_net_profit AS net_profit,
           cs_call_center_sk AS channel_sk,
           'catalog' AS channel,
           cs_promo_sk AS promo_sk
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_quantity,
           ss_ext_sales_price,
           ss_ext_discount_amt,
           ss_ext_tax,
           ss_net_profit,
           ss_store_sk,
           'store',
           ss_promo_sk
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_quantity,
           ws_ext_sales_price,
           ws_ext_discount_amt,
           ws_ext_tax,
           ws_net_profit,
           ws_web_page_sk,
           'web',
           ws_promo_sk
    FROM web_sales
),
returns AS (
    SELECT cr_returned_date_sk AS returned_date_sk,
           cr_item_sk AS item_sk,
           cr_return_quantity AS quantity,
           cr_return_amount AS return_amount,
           cr_return_tax AS return_tax,
           cr_net_loss AS net_loss,
           cr_call_center_sk AS channel_sk,
           'catalog' AS channel
    FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk,
           sr_item_sk,
           sr_return_quantity,
           sr_return_amt,
           sr_return_tax,
           sr_net_loss,
           sr_store_sk,
           'store'
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk,
           wr_item_sk,
           wr_return_quantity,
           wr_return_amt,
           wr_return_tax,
           wr_net_loss,
           wr_web_page_sk,
           'web'
    FROM web_returns
),
agg AS (
    SELECT d.d_year,
           s.channel,
           i.i_category,
           SUM(s.ext_sales_price) AS total_sales,
           SUM(s.ext_discount_amt) AS total_discount,
           SUM(s.net_profit) AS total_profit,
           COUNT(DISTINCT s.item_sk) AS distinct_items_sold,
           COUNT(DISTINCT CASE WHEN s.promo_sk IS NOT NULL THEN s.item_sk END) AS promo_items_sold,
           SUM(r.return_amount) AS total_returns,
           SUM(r.net_loss) AS total_return_loss,
           (SUM(r.return_amount) / NULLIF(SUM(s.ext_sales_price), 0)) AS return_ratio
    FROM sales s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN returns r
           ON s.item_sk = r.item_sk
          AND s.channel = r.channel
          AND s.channel_sk = r.channel_sk
          AND d.d_date_sk = r.returned_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, s.channel, i.i_category
    HAVING SUM(s.ext_sales_price) > 1000000
)
SELECT d_year,
       channel,
       i_category,
       total_sales,
       total_discount,
       total_profit,
       distinct_items_sold,
       promo_items_sold,
       total_returns,
       total_return_loss,
       return_ratio,
       profit_rank
FROM (
    SELECT a.*,
           ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank
    FROM agg a
) t
WHERE profit_rank <= 10
ORDER BY d_year, profit_rank
LIMIT 100
