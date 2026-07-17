WITH daily_item_sales AS (
    SELECT
        ws.ws_item_sk,
        i.i_product_name,
        ws.ws_web_site_sk,
        s.web_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS daily_net_profit,
        SUM(ws.ws_ext_sales_price) AS daily_sales,
        SUM(ws.ws_quantity) AS daily_quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    GROUP BY ws.ws_item_sk, i.i_product_name, ws.ws_web_site_sk, s.web_name, ws.ws_sold_date_sk
),

daily_item_returns AS (
    SELECT
        wr.wr_item_sk AS ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        SUM(wr.wr_return_amt_inc_tax) AS daily_return_amount,
        SUM(wr.wr_return_quantity) AS daily_return_quantity
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    GROUP BY wr.wr_item_sk, ws.ws_web_site_sk, ws.ws_sold_date_sk
),

daily_item_combined AS (
    SELECT
        s.ws_item_sk,
        s.i_product_name,
        s.ws_web_site_sk,
        s.web_name,
        s.ws_sold_date_sk,
        s.daily_net_profit,
        COALESCE(r.daily_return_amount, 0) AS daily_return_amount,
        s.daily_net_profit - COALESCE(r.daily_return_amount, 0) AS net_profit_after_returns,
        CASE 
            WHEN s.daily_net_profit - COALESCE(r.daily_return_amount, 0) > 1000 THEN 'High'
            WHEN s.daily_net_profit - COALESCE(r.daily_return_amount, 0) > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM daily_item_sales s
    LEFT JOIN daily_item_returns r
        ON s.ws_item_sk = r.ws_item_sk
        AND s.ws_web_site_sk = r.ws_web_site_sk
        AND s.ws_sold_date_sk = r.ws_sold_date_sk
)
SELECT
    d.ws_item_sk,
    d.i_product_name,
    d.ws_web_site_sk,
    d.web_name,
    d.ws_sold_date_sk,
    d.daily_net_profit,
    d.daily_return_amount,
    d.net_profit_after_returns,
    d.profit_category,
    SUM(d.net_profit_after_returns) OVER (
        PARTITION BY d.ws_web_site_sk
        ORDER BY d.ws_sold_date_sk
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_sum_profit_3_days,
    RANK() OVER (
        PARTITION BY d.ws_web_site_sk
        ORDER BY d.net_profit_after_returns DESC
    ) AS profit_rank_item,
    DENSE_RANK() OVER (
        PARTITION BY d.ws_web_site_sk
        ORDER BY d.profit_category
    ) AS profit_category_dense_rank,
    ROW_NUMBER() OVER (
        PARTITION BY d.ws_web_site_sk
        ORDER BY d.ws_sold_date_sk
    ) AS day_sequence
FROM daily_item_combined d
ORDER BY d.ws_web_site_sk, d.ws_sold_date_sk DESC
LIMIT 100
