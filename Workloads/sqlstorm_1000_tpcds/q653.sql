WITH
sales AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_date AS sales_date,
        i.i_item_id,
        i.i_category,
        i.i_class,
        i.i_brand,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
returns AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        d.d_date AS sales_date,
        i.i_item_id,
        i.i_category,
        i.i_class,
        i.i_brand,
        -sr.sr_return_quantity AS quantity,
        -sr.sr_return_amt AS net_paid,
        -sr.sr_net_loss AS net_profit,
        'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
),
cs_sales AS (
    SELECT
        cc.cc_call_center_sk AS store_sk,
        d.d_date AS sales_date,
        i.i_item_id,
        i.i_category,
        i.i_class,
        i.i_brand,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
),
cs_returns AS (
    SELECT
        cc.cc_call_center_sk AS store_sk,
        d.d_date AS sales_date,
        i.i_item_id,
        i.i_category,
        i.i_class,
        i.i_brand,
        -cr.cr_return_quantity AS quantity,
        -cr.cr_return_amount AS net_paid,
        -cr.cr_net_loss AS net_profit,
        'catalog' AS channel
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
),
ws_sales AS (
    SELECT
        ws.ws_web_page_sk AS store_sk,
        d.d_date AS sales_date,
        i.i_item_id,
        i.i_category,
        i.i_class,
        i.i_brand,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
ws_returns AS (
    SELECT
        wr.wr_web_page_sk AS store_sk,
        d.d_date AS sales_date,
        i.i_item_id,
        i.i_category,
        i.i_class,
        i.i_brand,
        -wr.wr_return_quantity AS quantity,
        -wr.wr_return_amt AS net_paid,
        -wr.wr_net_loss AS net_profit,
        'web' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
unified AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
    UNION ALL
    SELECT * FROM cs_sales
    UNION ALL
    SELECT * FROM cs_returns
    UNION ALL
    SELECT * FROM ws_sales
    UNION ALL
    SELECT * FROM ws_returns
),
sales_by_month AS (
    SELECT
        store_sk,
        date_trunc('month', sales_date) AS month,
        channel,
        i_category,
        i_class,
        i_brand,
        sum(quantity) AS total_quantity,
        sum(net_paid) AS total_net_paid,
        sum(net_profit) AS total_net_profit,
        approx_distinct(i_item_id) AS distinct_items_sold
    FROM unified
    GROUP BY
        store_sk,
        date_trunc('month', sales_date),
        channel,
        i_category,
        i_class,
        i_brand
),
ranked_items AS (
    SELECT
        store_sk,
        month,
        channel,
        i_brand,
        i_class,
        i_category,
        i_item_id,
        total_quantity,
        total_net_profit,
        row_number() OVER (PARTITION BY store_sk, month, channel, i_brand, i_class ORDER BY total_net_profit DESC) AS brand_class_item_rank
    FROM (
        SELECT
            store_sk,
            date_trunc('month', sales_date) AS month,
            channel,
            i_brand,
            i_class,
            i_category,
            i_item_id,
            sum(quantity) AS total_quantity,
            sum(net_profit) AS total_net_profit
        FROM unified
        GROUP BY
            store_sk,
            date_trunc('month', sales_date),
            channel,
            i_brand,
            i_class,
            i_category,
            i_item_id
    )
)
SELECT
    sbm.store_sk,
    sbm.month,
    sbm.channel,
    sbm.i_category,
    sbm.i_class,
    sbm.i_brand,
    sbm.total_quantity,
    sbm.total_net_paid,
    sbm.total_net_profit,
    sbm.distinct_items_sold,
    ri.i_item_id,
    ri.total_quantity AS top_item_quantity,
    ri.total_net_profit AS top_item_net_profit,
    ri.brand_class_item_rank
FROM sales_by_month sbm
LEFT JOIN ranked_items ri
    ON sbm.store_sk = ri.store_sk
   AND sbm.month = ri.month
   AND sbm.channel = ri.channel
   AND sbm.i_brand = ri.i_brand
   AND sbm.i_class = ri.i_class
   AND ri.brand_class_item_rank = 1
ORDER BY sbm.store_sk, sbm.month, sbm.channel
