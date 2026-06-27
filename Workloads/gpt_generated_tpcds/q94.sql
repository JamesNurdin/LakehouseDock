WITH sales AS (
    SELECT date_dim.d_date AS event_date,
           item.i_category AS category,
           store_sales.ss_net_paid_inc_tax AS sales_amount,
           store_sales.ss_net_profit AS profit,
           store_sales.ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    JOIN item ON store_sales.ss_item_sk = item.i_item_sk
    WHERE date_dim.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    UNION ALL
    SELECT date_dim.d_date AS event_date,
           item.i_category AS category,
           catalog_sales.cs_net_paid_inc_tax AS sales_amount,
           catalog_sales.cs_net_profit AS profit,
           catalog_sales.cs_quantity AS quantity,
           'catalog' AS channel
    FROM catalog_sales
    JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
    JOIN item ON catalog_sales.cs_item_sk = item.i_item_sk
    WHERE date_dim.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    UNION ALL
    SELECT date_dim.d_date AS event_date,
           item.i_category AS category,
           web_sales.ws_net_paid_inc_tax AS sales_amount,
           web_sales.ws_net_profit AS profit,
           web_sales.ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales
    JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    JOIN item ON web_sales.ws_item_sk = item.i_item_sk
    WHERE date_dim.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
returns AS (
    SELECT date_dim.d_date AS event_date,
           item.i_category AS category,
           store_returns.sr_return_amt_inc_tax AS return_amount,
           store_returns.sr_net_loss AS return_loss,
           store_returns.sr_return_quantity AS return_quantity,
           'store' AS channel
    FROM store_returns
    JOIN date_dim ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
    JOIN item ON store_returns.sr_item_sk = item.i_item_sk
    WHERE date_dim.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    UNION ALL
    SELECT date_dim.d_date AS event_date,
           item.i_category AS category,
           catalog_returns.cr_return_amt_inc_tax AS return_amount,
           catalog_returns.cr_net_loss AS return_loss,
           catalog_returns.cr_return_quantity AS return_quantity,
           'catalog' AS channel
    FROM catalog_returns
    JOIN date_dim ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
    JOIN item ON catalog_returns.cr_item_sk = item.i_item_sk
    WHERE date_dim.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    UNION ALL
    SELECT date_dim.d_date AS event_date,
           item.i_category AS category,
           web_returns.wr_return_amt_inc_tax AS return_amount,
           web_returns.wr_net_loss AS return_loss,
           web_returns.wr_return_quantity AS return_quantity,
           'web' AS channel
    FROM web_returns
    JOIN date_dim ON web_returns.wr_returned_date_sk = date_dim.d_date_sk
    JOIN item ON web_returns.wr_item_sk = item.i_item_sk
    WHERE date_dim.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
)
SELECT
    d.event_date,
    d.category,
    sum(sales.sales_amount) AS total_sales_amount,
    sum(sales.profit) AS total_sales_profit,
    sum(sales.quantity) AS total_quantity_sold,
    sum(returns.return_amount) AS total_return_amount,
    sum(returns.return_loss) AS total_return_loss,
    sum(returns.return_quantity) AS total_quantity_returned,
    sum(sales.profit) - coalesce(sum(returns.return_loss), 0) AS net_profit_after_returns
FROM (
    SELECT event_date, category FROM sales
    UNION
    SELECT event_date, category FROM returns
) d
LEFT JOIN sales ON sales.event_date = d.event_date AND sales.category = d.category
LEFT JOIN returns ON returns.event_date = d.event_date AND returns.category = d.category
GROUP BY d.event_date, d.category
ORDER BY d.event_date, d.category
