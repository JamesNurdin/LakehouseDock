WITH
sales AS (
    SELECT
        cs_sold_date_sk AS date_sk,
        CAST(NULL AS integer) AS store_sk,
        CAST(NULL AS integer) AS web_sk,
        cs_call_center_sk AS catalog_sk,
        cs_item_sk AS item_sk,
        cs_quantity AS quantity,
        cs_net_profit AS net_profit,
        cs_net_paid AS net_paid,
        'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT
        ss_sold_date_sk,
        ss_store_sk,
        CAST(NULL AS integer) AS web_sk,
        CAST(NULL AS integer) AS catalog_sk,
        ss_item_sk,
        ss_quantity,
        ss_net_profit,
        ss_net_paid,
        'store'
    FROM store_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        CAST(NULL AS integer) AS store_sk,
        ws_web_page_sk,
        CAST(NULL AS integer) AS catalog_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ws_net_paid,
        'web'
    FROM web_sales
),
returns AS (
    SELECT
        cr_returned_date_sk AS date_sk,
        CAST(NULL AS integer) AS store_sk,
        CAST(NULL AS integer) AS web_sk,
        cr_call_center_sk AS catalog_sk,
        cr_item_sk AS item_sk,
        cr_return_quantity AS quantity,
        cr_net_loss AS net_loss,
        'catalog' AS channel
    FROM catalog_returns
    UNION ALL
    SELECT
        sr_returned_date_sk,
        sr_store_sk,
        CAST(NULL AS integer) AS web_sk,
        CAST(NULL AS integer) AS catalog_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_net_loss,
        'store'
    FROM store_returns
    UNION ALL
    SELECT
        wr_returned_date_sk,
        CAST(NULL AS integer) AS store_sk,
        wr_web_page_sk,
        CAST(NULL AS integer) AS catalog_sk,
        wr_item_sk,
        wr_return_quantity,
        wr_net_loss,
        'web'
    FROM web_returns
),
joined AS (
    SELECT
        s.date_sk,
        d.d_year,
        d.d_moy AS month,
        s.channel,
        i.i_category,
        i.i_brand,
        s.item_sk,
        s.store_sk,
        s.web_sk,
        s.catalog_sk,
        s.quantity AS sales_qty,
        s.net_profit,
        s.net_paid,
        COALESCE(r.quantity, 0) AS return_qty,
        COALESCE(r.net_loss, 0) AS net_loss
    FROM sales s
    LEFT JOIN returns r
        ON s.date_sk = r.date_sk
       AND s.channel = r.channel
       AND s.item_sk = r.item_sk
       AND (
            (s.channel = 'store' AND s.store_sk = r.store_sk) OR
            (s.channel = 'web' AND s.web_sk = r.web_sk) OR
            (s.channel = 'catalog' AND s.catalog_sk = r.catalog_sk)
           )
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
),
monthly AS (
    SELECT
        d_year,
        month,
        channel,
        i_category,
        i_brand,
        SUM(net_profit) AS total_profit,
        SUM(net_paid) AS total_sales,
        SUM(net_loss) AS total_losses,
        SUM(net_profit) - SUM(net_loss) AS net_profit_after_returns,
        SUM(sales_qty) AS total_qty_sold,
        SUM(return_qty) AS total_qty_returned,
        COUNT(DISTINCT item_sk) AS distinct_items_sold,
        COUNT(DISTINCT CASE WHEN channel = 'store' THEN store_sk END) AS distinct_stores,
        COUNT(DISTINCT CASE WHEN channel = 'web' THEN web_sk END) AS distinct_web_pages,
        COUNT(DISTINCT CASE WHEN channel = 'catalog' THEN catalog_sk END) AS distinct_call_centers,
        AVG(sales_qty) AS avg_qty_per_sale
    FROM joined
    GROUP BY d_year, month, channel, i_category, i_brand
)
SELECT
    d_year,
    month,
    channel,
    i_category,
    i_brand,
    total_profit,
    total_sales,
    total_losses,
    net_profit_after_returns,
    total_qty_sold,
    total_qty_returned,
    distinct_items_sold,
    distinct_stores,
    distinct_web_pages,
    distinct_call_centers,
    avg_qty_per_sale,
    LAG(total_profit) OVER (PARTITION BY channel, i_category, i_brand ORDER BY d_year, month) AS prev_month_profit,
    CASE
        WHEN LAG(total_profit) OVER (PARTITION BY channel, i_category, i_brand ORDER BY d_year, month) IS NULL THEN NULL
        ELSE (total_profit - LAG(total_profit) OVER (PARTITION BY channel, i_category, i_brand ORDER BY d_year, month)) /
            NULLIF(LAG(total_profit) OVER (PARTITION BY channel, i_category, i_brand ORDER BY d_year, month), 0)
    END AS mom_profit_growth
FROM monthly
WHERE d_year BETWEEN 1999 AND 2002
ORDER BY d_year, month, channel, i_category, i_brand
