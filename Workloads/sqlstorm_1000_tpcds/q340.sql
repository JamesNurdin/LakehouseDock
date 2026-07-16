WITH sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_call_center_sk AS loc_sk,
        'call_center' AS loc_type,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS revenue,
        cs.cs_net_profit AS profit,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_store_sk AS loc_sk,
        'store' AS loc_type,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS revenue,
        ss.ss_net_profit AS profit,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_web_page_sk AS loc_sk,
        'web_page' AS loc_type,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS revenue,
        ws.ws_net_profit AS profit,
        'web' AS channel
    FROM web_sales ws
),
returns AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_call_center_sk AS loc_sk,
        'call_center' AS loc_type,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS quantity,
        -cr.cr_return_amount AS revenue,
        -cr.cr_net_loss AS profit,
        'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_store_sk AS loc_sk,
        'store' AS loc_type,
        sr.sr_item_sk AS item_sk,
        sr.sr_return_quantity AS quantity,
        -sr.sr_return_amt AS revenue,
        -sr.sr_net_loss AS profit,
        'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_web_page_sk AS loc_sk,
        'web_page' AS loc_type,
        wr.wr_item_sk AS item_sk,
        wr.wr_return_quantity AS quantity,
        -wr.wr_return_amt AS revenue,
        -wr.wr_net_loss AS profit,
        'web' AS channel
    FROM web_returns wr
),
combined AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
),
aggregated AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        c.channel,
        COALESCE(cc.cc_name, st.s_store_name, wp.wp_type) AS location_name,
        i.i_category,
        i.i_brand,
        SUM(c.revenue) AS total_revenue,
        SUM(c.profit) AS total_profit,
        COUNT(DISTINCT c.item_sk) AS distinct_items_sold,
        AVG(CASE WHEN c.quantity <> 0 THEN c.revenue / c.quantity END) AS avg_price_per_unit
    FROM combined c
    JOIN date_dim d ON c.date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON c.loc_type = 'call_center' AND c.loc_sk = cc.cc_call_center_sk
    LEFT JOIN store st ON c.loc_type = 'store' AND c.loc_sk = st.s_store_sk
    LEFT JOIN web_page wp ON c.loc_type = 'web_page' AND c.loc_sk = wp.wp_web_page_sk
    LEFT JOIN item i ON c.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY
        d.d_year,
        d.d_month_seq,
        c.channel,
        COALESCE(cc.cc_name, st.s_store_name, wp.wp_type),
        i.i_category,
        i.i_brand
    HAVING SUM(c.revenue) > 0
)
SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated a
ORDER BY d_year, d_month_seq, channel, total_revenue DESC
LIMIT 100
