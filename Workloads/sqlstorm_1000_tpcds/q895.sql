WITH cat_sales AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_net_paid) AS revenue,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
),
cat_ret AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        'catalog' AS channel,
        SUM(cr.cr_net_loss) AS loss,
        SUM(cr.cr_return_quantity) AS ret_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
),
store_sales AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_net_paid) AS revenue,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
),
store_ret AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        'store' AS channel,
        SUM(sr.sr_net_loss) AS loss,
        SUM(sr.sr_return_quantity) AS ret_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
),
web_sales AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_net_paid) AS revenue,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
),
web_ret AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        'web' AS channel,
        SUM(wr.wr_net_loss) AS loss,
        SUM(wr.wr_return_quantity) AS ret_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
),
combined AS (
    SELECT
        cs.year,
        cs.category,
        cs.class,
        cs.brand,
        cs.channel,
        cs.profit - COALESCE(cr.loss, 0) AS net_profit,
        cs.revenue - COALESCE(cr.loss, 0) AS net_revenue,
        cs.orders,
        COALESCE(cr.ret_qty, 0) AS return_qty
    FROM cat_sales cs
    LEFT JOIN cat_ret cr
        ON cs.year = cr.year
        AND cs.category = cr.category
        AND cs.class = cr.class
        AND cs.brand = cr.brand
        AND cs.channel = cr.channel

    UNION ALL

    SELECT
        ss.year,
        ss.category,
        ss.class,
        ss.brand,
        ss.channel,
        ss.profit - COALESCE(sr.loss, 0) AS net_profit,
        ss.revenue - COALESCE(sr.loss, 0) AS net_revenue,
        ss.orders,
        COALESCE(sr.ret_qty, 0) AS return_qty
    FROM store_sales ss
    LEFT JOIN store_ret sr
        ON ss.year = sr.year
        AND ss.category = sr.category
        AND ss.class = sr.class
        AND ss.brand = sr.brand
        AND ss.channel = sr.channel

    UNION ALL

    SELECT
        ws.year,
        ws.category,
        ws.class,
        ws.brand,
        ws.channel,
        ws.profit - COALESCE(wr.loss, 0) AS net_profit,
        ws.revenue - COALESCE(wr.loss, 0) AS net_revenue,
        ws.orders,
        COALESCE(wr.ret_qty, 0) AS return_qty
    FROM web_sales ws
    LEFT JOIN web_ret wr
        ON ws.year = wr.year
        AND ws.category = wr.category
        AND ws.class = wr.class
        AND ws.brand = wr.brand
        AND ws.channel = wr.channel
)
SELECT
    year,
    channel,
    category,
    class,
    brand,
    total_net_profit,
    total_net_revenue,
    total_orders,
    total_return_quantity,
    RANK() OVER (PARTITION BY year ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        year,
        channel,
        category,
        class,
        brand,
        SUM(net_profit) AS total_net_profit,
        SUM(net_revenue) AS total_net_revenue,
        SUM(orders) AS total_orders,
        SUM(return_qty) AS total_return_quantity
    FROM combined
    WHERE year BETWEEN 1999 AND 2000
    GROUP BY year, channel, category, class, brand
) t
ORDER BY total_net_profit DESC
LIMIT 100
