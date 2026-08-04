WITH catalog_sales_agg AS (
    SELECT
        c.c_customer_id,
        'Catalog' AS sales_channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        (
            SELECT COALESCE(SUM(sr.sr_return_amt), 0)
            FROM store_returns sr
            WHERE sr.sr_customer_sk = c.c_customer_sk
        ) AS total_returns
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_current_price > (
            SELECT AVG(i2.i_current_price)
            FROM item i2
            WHERE i2.i_brand = i.i_brand
        )
        AND d.d_year = 2002
    GROUP BY c.c_customer_id, c.c_customer_sk
),
web_sales_agg AS (
    SELECT
        c.c_customer_id,
        'Web' AS sales_channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        (
            SELECT COALESCE(SUM(sr.sr_return_amt), 0)
            FROM store_returns sr
            WHERE sr.sr_customer_sk = c.c_customer_sk
        ) AS total_returns
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > (
            SELECT AVG(i2.i_current_price)
            FROM item i2
            WHERE i2.i_brand = i.i_brand
        )
        AND d.d_year = 2002
    GROUP BY c.c_customer_id, c.c_customer_sk
)
SELECT *
FROM catalog_sales_agg
UNION ALL
SELECT *
FROM web_sales_agg
ORDER BY total_sales DESC, sales_channel
