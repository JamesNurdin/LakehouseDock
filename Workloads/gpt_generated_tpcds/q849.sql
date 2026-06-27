WITH sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'catalog' AS channel,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_sales_price AS ext_sales,
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        'web' AS channel,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_sales_price AS ext_sales,
        ws.ws_order_number AS order_number,
        ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
aggregated AS (
    SELECT
        d_year,
        d_month_seq,
        channel,
        SUM(net_profit) AS total_net_profit,
        SUM(ext_sales) AS total_sales,
        COUNT(DISTINCT order_number) AS orders,
        SUM(quantity) AS total_quantity
    FROM sales
    GROUP BY d_year, d_month_seq, channel
),
store_closures AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COUNT(*) AS closed_stores
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
ranked AS (
    SELECT
        a.d_year,
        a.d_month_seq,
        a.channel,
        a.total_net_profit,
        a.total_sales,
        a.orders,
        a.total_quantity,
        ROW_NUMBER() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.total_net_profit DESC) AS rank,
        COALESCE(sc.closed_stores, 0) AS closed_stores
    FROM aggregated a
    LEFT JOIN store_closures sc ON sc.d_year = a.d_year AND sc.d_month_seq = a.d_month_seq
)
SELECT
    d_year,
    d_month_seq,
    channel,
    total_net_profit,
    total_sales,
    orders,
    total_quantity,
    closed_stores
FROM ranked
WHERE rank <= 2
ORDER BY d_year, d_month_seq, rank
