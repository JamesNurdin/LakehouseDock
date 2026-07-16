WITH unified AS (
    SELECT d.d_year AS sale_year,
           d.d_month_seq AS sale_month,
           i.i_category AS category,
           i.i_class AS class,
           i.i_brand AS brand,
           'web' AS channel,
           ws.ws_ext_sales_price AS sales_amount,
           ws.ws_net_profit AS profit,
           CAST(0 AS decimal(7,2)) AS loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_class,
           i.i_brand,
           'store',
           ss.ss_ext_sales_price,
           ss.ss_net_profit,
           CAST(0 AS decimal(7,2))
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_class,
           i.i_brand,
           'catalog',
           cs.cs_ext_sales_price,
           cs.cs_net_profit,
           CAST(0 AS decimal(7,2))
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_class,
           i.i_brand,
           'web',
           -wr.wr_return_amt,
           CAST(0 AS decimal(7,2)),
           wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_class,
           i.i_brand,
           'store',
           -sr.sr_return_amt,
           CAST(0 AS decimal(7,2)),
           sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_class,
           i.i_brand,
           'catalog',
           -cr.cr_return_amount,
           CAST(0 AS decimal(7,2)),
           cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
),
aggregated AS (
    SELECT sale_year,
           sale_month,
           category,
           class,
           brand,
           channel,
           SUM(sales_amount) AS total_sales,
           SUM(profit) AS total_profit,
           SUM(loss) AS total_loss,
           SUM(sales_amount) - SUM(loss) AS net_sales,
           SUM(profit) - SUM(loss) AS net_profit
    FROM unified
    WHERE sale_year BETWEEN 1999 AND 2002
    GROUP BY sale_year, sale_month, category, class, brand, channel
)
SELECT
    sale_year,
    sale_month,
    category,
    class,
    brand,
    channel,
    total_sales,
    total_profit,
    total_loss,
    net_sales,
    net_profit,
    RANK() OVER (PARTITION BY channel ORDER BY net_profit DESC) AS profit_rank
FROM aggregated
WHERE net_profit > 0
ORDER BY sale_year, sale_month, channel, profit_rank
LIMIT 200
