WITH catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_product_name AS product_name,
        i.i_item_sk AS item_sk,
        cs.cs_net_paid_inc_tax AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_order_number AS order_number,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
store_sales_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_product_name AS product_name,
        i.i_item_sk AS item_sk,
        ss.ss_net_paid_inc_tax AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_ticket_number AS order_number,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_product_name AS product_name,
        i.i_item_sk AS item_sk,
        ws.ws_net_paid_inc_tax AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_order_number AS order_number,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
all_sales AS (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
returns_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_order_number AS order_number,
        (cr.cr_return_amount + cr.cr_return_tax + cr.cr_fee) AS return_amount,
        'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_ticket_number,
        (sr.sr_return_amt + sr.sr_return_tax + sr.sr_fee) AS return_amount,
        'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_order_number,
        (wr.wr_return_amt + wr.wr_return_tax + wr.wr_fee) AS return_amount,
        'web' AS channel
    FROM web_returns wr
),
sales_returns AS (
    SELECT
        s.year,
        s.category,
        s.product_name,
        s.item_sk,
        s.channel,
        s.net_paid,
        s.net_profit,
        s.discount_amt,
        COALESCE(r.return_amount, 0) AS return_amount
    FROM all_sales s
    LEFT JOIN returns_agg r
        ON s.order_number = r.order_number
        AND s.item_sk = r.item_sk
        AND s.channel = r.channel
),
product_metrics AS (
    SELECT
        year,
        category,
        channel,
        product_name,
        SUM(net_paid) AS total_sales,
        SUM(net_profit) AS total_profit,
        SUM(discount_amt) AS total_discount,
        SUM(return_amount) AS total_returns,
        SUM(net_paid) - SUM(return_amount) AS net_sales,
        SUM(net_profit) - SUM(return_amount) AS net_profit_adj,
        CASE WHEN (SUM(net_paid) - SUM(return_amount)) = 0 THEN 0
             ELSE (SUM(net_profit) - SUM(return_amount)) / (SUM(net_paid) - SUM(return_amount))
        END AS profit_margin,
        ROW_NUMBER() OVER (PARTITION BY year, channel, category ORDER BY SUM(net_profit) DESC) AS profit_rank
    FROM sales_returns
    GROUP BY year, category, channel, product_name
)
SELECT
    year,
    category,
    channel,
    product_name,
    total_sales,
    total_profit,
    total_discount,
    total_returns,
    net_sales,
    net_profit_adj,
    profit_margin,
    profit_rank
FROM product_metrics
WHERE profit_rank <= 5
ORDER BY year, channel, category, profit_rank
LIMIT 200
