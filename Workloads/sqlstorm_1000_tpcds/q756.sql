WITH sales AS (
    SELECT d.d_year,
           cs.cs_item_sk AS item_sk,
           cs.cs_ext_sales_price AS sales_amount,
           cs.cs_net_profit AS profit,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year,
           ss.ss_item_sk,
           ss.ss_ext_sales_price,
           ss.ss_net_profit,
           'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year,
           ws.ws_item_sk,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
returns AS (
    SELECT d.d_year,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_amount AS return_amount,
           'catalog' AS channel
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year,
           sr.sr_item_sk,
           sr.sr_return_amt,
           'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year,
           wr.wr_item_sk,
           wr.wr_return_amt,
           'web' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),
item_agg AS (
    SELECT
        s.d_year,
        s.channel,
        s.item_sk,
        SUM(s.sales_amount) AS total_sales,
        SUM(s.profit) AS total_profit,
        COALESCE(SUM(r.return_amount), 0) AS total_returns
    FROM sales s
    LEFT JOIN returns r
        ON s.d_year = r.d_year
        AND s.channel = r.channel
        AND s.item_sk = r.item_sk
    GROUP BY s.d_year, s.channel, s.item_sk
),
year_channel_agg AS (
    SELECT
        d_year,
        channel,
        SUM(total_sales) AS sales,
        SUM(total_returns) AS returns,
        SUM(total_sales) - SUM(total_returns) AS net_sales,
        SUM(total_profit) AS profit
    FROM item_agg
    GROUP BY d_year, channel
),
item_rank AS (
    SELECT
        ia.d_year,
        ia.channel,
        ia.item_sk,
        i.i_product_name,
        ia.total_profit,
        RANK() OVER (PARTITION BY ia.d_year, ia.channel ORDER BY ia.total_profit DESC) AS profit_rank
    FROM item_agg ia
    JOIN item i ON ia.item_sk = i.i_item_sk
)
SELECT
    yc.d_year,
    yc.channel,
    yc.sales,
    yc.returns,
    yc.net_sales,
    yc.profit,
    ir.item_sk,
    ir.i_product_name,
    ir.total_profit,
    ir.profit_rank
FROM year_channel_agg yc
JOIN item_rank ir
    ON yc.d_year = ir.d_year
    AND yc.channel = ir.channel
WHERE ir.profit_rank <= 5
ORDER BY yc.d_year, yc.channel, ir.profit_rank
