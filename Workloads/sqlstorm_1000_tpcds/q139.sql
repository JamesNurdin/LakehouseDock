WITH sales_union AS (
    SELECT
        'store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_store_sk AS location_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    UNION ALL
    SELECT
        'catalog' AS channel,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS location_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT
        'web' AS channel,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_web_page_sk AS location_sk,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS ext_sales,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
),
returns_union AS (
    SELECT
        'store' AS channel,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_store_sk AS location_sk,
        sr.sr_return_quantity AS quantity,
        sr.sr_return_amt AS return_amt,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    UNION ALL
    SELECT
        'catalog' AS channel,
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_call_center_sk AS location_sk,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amount AS return_amt,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT
        'web' AS channel,
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_item_sk AS item_sk,
        wr.wr_web_page_sk AS location_sk,
        wr.wr_return_quantity AS quantity,
        wr.wr_return_amt AS return_amt,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
),
sales_agg AS (
    SELECT
        su.channel,
        d.d_year,
        i.i_category,
        i.i_class,
        su.item_sk,
        su.location_sk,
        SUM(su.quantity) AS total_quantity,
        SUM(su.ext_sales) AS total_sales,
        SUM(su.net_paid) AS total_net_paid,
        SUM(su.net_profit) AS total_net_profit
    FROM sales_union su
    JOIN date_dim d ON su.date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    GROUP BY
        su.channel,
        d.d_year,
        i.i_category,
        i.i_class,
        su.item_sk,
        su.location_sk
),
returns_agg AS (
    SELECT
        ru.channel,
        d.d_year,
        i.i_category,
        i.i_class,
        ru.item_sk,
        ru.location_sk,
        SUM(ru.quantity) AS total_return_quantity,
        SUM(ru.return_amt) AS total_return_amount,
        SUM(ru.net_loss) AS total_return_loss
    FROM returns_union ru
    JOIN date_dim d ON ru.date_sk = d.d_date_sk
    JOIN item i ON ru.item_sk = i.i_item_sk
    GROUP BY
        ru.channel,
        d.d_year,
        i.i_category,
        i.i_class,
        ru.item_sk,
        ru.location_sk
),
combined AS (
    SELECT
        sa.channel,
        sa.d_year,
        sa.i_category,
        sa.i_class,
        sa.item_sk,
        sa.location_sk,
        sa.total_quantity,
        sa.total_sales,
        sa.total_net_paid,
        sa.total_net_profit,
        COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        (sa.total_sales - COALESCE(ra.total_return_amount, 0)) AS net_sales_after_returns,
        (sa.total_net_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
      ON sa.channel = ra.channel
     AND sa.d_year = ra.d_year
     AND sa.i_category = ra.i_category
     AND sa.i_class = ra.i_class
     AND sa.item_sk = ra.item_sk
     AND sa.location_sk = ra.location_sk
),
ranked AS (
    SELECT
        c.channel,
        c.d_year,
        c.i_category,
        c.i_class,
        c.item_sk,
        c.location_sk,
        c.total_quantity,
        c.total_sales,
        c.total_net_paid,
        c.total_net_profit,
        c.total_return_quantity,
        c.total_return_amount,
        c.total_return_loss,
        c.net_sales_after_returns,
        c.net_profit_after_returns,
        ROW_NUMBER() OVER (PARTITION BY c.channel, c.d_year, c.i_category ORDER BY c.net_profit_after_returns DESC) AS profit_rank,
        RANK() OVER (PARTITION BY c.channel, c.d_year, c.i_category ORDER BY c.net_sales_after_returns DESC) AS sales_rank
    FROM combined c
)
SELECT
    r.channel,
    r.d_year,
    r.i_category,
    r.i_class,
    i.i_product_name,
    CASE
        WHEN r.channel = 'store' THEN s.s_store_name
        WHEN r.channel = 'catalog' THEN cc.cc_name
        WHEN r.channel = 'web' THEN wp.wp_url
    END AS location_name,
    r.total_quantity,
    r.total_sales,
    r.total_net_paid,
    r.total_net_profit,
    r.total_return_quantity,
    r.total_return_amount,
    r.total_return_loss,
    r.net_sales_after_returns,
    r.net_profit_after_returns,
    r.profit_rank,
    r.sales_rank
FROM ranked r
JOIN item i ON r.item_sk = i.i_item_sk
LEFT JOIN store s ON r.channel = 'store' AND r.location_sk = s.s_store_sk
LEFT JOIN call_center cc ON r.channel = 'catalog' AND r.location_sk = cc.cc_call_center_sk
LEFT JOIN web_page wp ON r.channel = 'web' AND r.location_sk = wp.wp_web_page_sk
WHERE r.profit_rank <= 10
ORDER BY r.channel, r.d_year, r.i_category, r.profit_rank
