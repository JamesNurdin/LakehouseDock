WITH agg_item AS (
    SELECT
        i.i_item_sk,
        i.i_brand AS brand,
        d_sold.d_year,
        cd.cd_gender,
        ws.profit_flag,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM (
        SELECT
            ws.*,
            CASE
                WHEN ws.ws_net_profit > 0 THEN 'Profit'
                WHEN ws.ws_net_profit = 0 THEN 'BreakEven'
                ELSE 'Loss'
            END AS profit_flag
        FROM web_sales ws
    ) ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim d_wp_create
        ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
    JOIN date_dim d_ws_open
        ON wsite.web_open_date_sk = d_ws_open.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001                         -- filter 1: specific year
      AND i.i_brand_id = 5                             -- filter 2: brand identifier
      AND cd.cd_gender = 'M'                           -- filter 3: gender
      AND ws.ws_ext_sales_price > 1000                -- filter 4: sales amount threshold
      AND EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = i.i_item_sk
              AND sr2.sr_return_quantity > 2        -- subquery filter
        )
    GROUP BY i.i_item_sk, i.i_brand, d_sold.d_year, cd.cd_gender, ws.profit_flag
)
SELECT
    brand,
    AVG(total_profit) AS avg_profit,
    SUM(total_sales) AS sum_sales,
    SUM(order_cnt) AS total_orders
FROM agg_item
GROUP BY brand
HAVING AVG(total_profit) > 5000                       -- having filter on derived aggregate
ORDER BY avg_profit DESC
LIMIT 100
