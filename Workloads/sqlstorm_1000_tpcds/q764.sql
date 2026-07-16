WITH
sales AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_order_number AS order_number,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_discount_amt AS discount_amt,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_ticket_number,
           ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_ext_discount_amt,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_order_number,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_ext_discount_amt,
           'web'
    FROM web_sales ws
),
returns AS (
    SELECT cr.cr_returned_date_sk AS returned_date_sk,
           cr.cr_order_number AS order_number,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_quantity AS quantity,
           cr.cr_return_amount AS amount,
           'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_ticket_number,
           sr.sr_item_sk,
           sr.sr_return_quantity,
           sr.sr_return_amt,
           'store'
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_order_number,
           wr.wr_item_sk,
           wr.wr_return_quantity,
           wr.wr_return_amt,
           'web'
    FROM web_returns wr
),
sales_agg AS (
    SELECT 
        s.channel,
        d.d_year AS year,
        d.d_qoy AS quarter,
        i.i_category AS category,
        i.i_class AS class,
        SUM(s.quantity) AS total_units_sold,
        SUM(s.net_paid) AS total_revenue,
        SUM(s.net_profit) AS total_profit,
        AVG(CASE WHEN s.quantity > 0 THEN s.discount_amt / s.quantity END) AS avg_discount_per_item
    FROM sales s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY GROUPING SETS (
        (s.channel, d.d_year, d.d_qoy, i.i_category, i.i_class),
        (s.channel, d.d_year, d.d_qoy, i.i_category),
        (s.channel, d.d_year, d.d_qoy),
        (s.channel, d.d_year),
        (s.channel)
    )
),
returns_agg AS (
    SELECT 
        r.channel,
        d.d_year AS year,
        d.d_qoy AS quarter,
        i.i_category AS category,
        i.i_class AS class,
        SUM(r.quantity) AS total_units_returned,
        SUM(r.amount) AS total_return_amount
    FROM returns r
    JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY GROUPING SETS (
        (r.channel, d.d_year, d.d_qoy, i.i_category, i.i_class),
        (r.channel, d.d_year, d.d_qoy, i.i_category),
        (r.channel, d.d_year, d.d_qoy),
        (r.channel, d.d_year),
        (r.channel)
    )
),
combined AS (
    SELECT 
        COALESCE(s.channel, r.channel) AS channel,
        COALESCE(s.year, r.year) AS year,
        COALESCE(s.quarter, r.quarter) AS quarter,
        COALESCE(s.category, r.category) AS category,
        COALESCE(s.class, r.class) AS class,
        COALESCE(s.total_units_sold, 0) AS total_units_sold,
        COALESCE(s.total_revenue, 0) AS total_revenue,
        COALESCE(s.total_profit, 0) AS total_profit,
        COALESCE(s.avg_discount_per_item, 0) AS avg_discount_per_item,
        COALESCE(r.total_units_returned, 0) AS total_units_returned,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        CASE WHEN COALESCE(s.total_revenue, 0) = 0 THEN 0
             ELSE COALESCE(r.total_return_amount, 0) / s.total_revenue END AS return_rate
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
        ON s.channel = r.channel
       AND s.year = r.year
       AND s.quarter = r.quarter
       AND s.category = r.category
       AND s.class = r.class
),
ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY channel, year ORDER BY total_profit DESC) AS profit_rank,
        RANK() OVER (PARTITION BY channel ORDER BY total_units_sold DESC) AS sales_volume_rank
    FROM combined
)
SELECT 
    channel,
    year,
    quarter,
    category,
    class,
    total_units_sold,
    total_revenue,
    total_profit,
    avg_discount_per_item,
    total_units_returned,
    total_return_amount,
    return_rate,
    profit_rank,
    sales_volume_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY channel, year DESC, profit_rank
