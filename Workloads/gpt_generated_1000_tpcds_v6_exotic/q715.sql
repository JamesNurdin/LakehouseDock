WITH store_sales_part AS (
    SELECT
        d.d_date AS sale_date,
        i.i_product_name AS product,
        ss.ss_ext_sales_price AS sales_amount,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        'Store' AS channel,
        (
            SELECT MAX(i2.i_current_price)
            FROM item i2
            WHERE i2.i_category = i.i_category
        ) AS max_price_in_category
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'red'
      AND c.c_preferred_cust_flag = 'Y'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = c.c_customer_sk
            AND sr.sr_net_loss > 0
      )
),
web_sales_part AS (
    SELECT
        d.d_date AS sale_date,
        i.i_product_name AS product,
        ws.ws_ext_sales_price AS sales_amount,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        'Web' AS channel,
        (
            SELECT MAX(i2.i_current_price)
            FROM item i2
            WHERE i2.i_category = i.i_category
        ) AS max_price_in_category
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'red'
      AND c.c_preferred_cust_flag = 'Y'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = c.c_customer_sk
            AND sr.sr_net_loss > 0
      )
)
SELECT * FROM store_sales_part
UNION ALL
SELECT * FROM web_sales_part
ORDER BY sale_date DESC, sales_amount DESC
LIMIT 100
