WITH date_q1 AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2022
      AND d_moy BETWEEN 1 AND 3
),
sales_union AS (
    SELECT
        i.i_category,
        i.i_brand,
        i.i_class,
        i.i_item_id,
        'store' AS channel,
        SUM(ss.ss_quantity) AS qty_sold,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_ext_discount_amt + ss.ss_coupon_amt) AS discount_amount,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_q1 d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_category, i.i_brand, i.i_class, i.i_item_id

    UNION ALL

    SELECT
        i.i_category,
        i.i_brand,
        i.i_class,
        i.i_item_id,
        'catalog' AS channel,
        SUM(cs.cs_quantity) AS qty_sold,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        SUM(cs.cs_ext_discount_amt + cs.cs_coupon_amt) AS discount_amount,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_q1 d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category, i.i_brand, i.i_class, i.i_item_id

    UNION ALL

    SELECT
        i.i_category,
        i.i_brand,
        i.i_class,
        i.i_item_id,
        'web' AS channel,
        SUM(ws.ws_quantity) AS qty_sold,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        SUM(ws.ws_ext_discount_amt + ws.ws_coupon_amt) AS discount_amount,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_q1 d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_category, i.i_brand, i.i_class, i.i_item_id
),
returns_union AS (
    SELECT
        i.i_category,
        i.i_brand,
        i.i_class,
        i.i_item_id,
        'store' AS channel,
        SUM(sr.sr_return_quantity) AS qty_returned,
        SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN date_q1 d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_category, i.i_brand, i.i_class, i.i_item_id

    UNION ALL

    SELECT
        i.i_category,
        i.i_brand,
        i.i_class,
        i.i_item_id,
        'catalog' AS channel,
        SUM(cr.cr_return_quantity) AS qty_returned,
        SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN date_q1 d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_category, i.i_brand, i.i_class, i.i_item_id

    UNION ALL

    SELECT
        i.i_category,
        i.i_brand,
        i.i_class,
        i.i_item_id,
        'web' AS channel,
        SUM(wr.wr_return_quantity) AS qty_returned,
        SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN date_q1 d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_category, i.i_brand, i.i_class, i.i_item_id
),
combined AS (
    SELECT
        s.i_category,
        s.i_brand,
        s.i_class,
        s.i_item_id,
        s.channel,
        s.qty_sold,
        s.sales_amount,
        s.discount_amount,
        s.net_paid,
        s.net_profit,
        COALESCE(r.qty_returned, 0) AS qty_returned,
        COALESCE(r.net_loss, 0) AS net_loss
    FROM sales_union s
    LEFT JOIN returns_union r
        ON s.i_category = r.i_category
        AND s.i_brand = r.i_brand
        AND s.i_class = r.i_class
        AND s.i_item_id = r.i_item_id
        AND s.channel = r.channel
),
agg AS (
    SELECT
        i_category,
        i_brand,
        i_class,
        channel,
        SUM(qty_sold) AS total_qty_sold,
        SUM(sales_amount) AS total_sales,
        SUM(discount_amount) AS total_discount,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(qty_returned) AS total_qty_returned,
        SUM(net_loss) AS total_net_loss
    FROM combined
    GROUP BY i_category, i_brand, i_class, channel
),
final_metrics AS (
    SELECT
        i_category,
        i_brand,
        i_class,
        channel,
        total_qty_sold,
        total_sales,
        total_discount,
        total_qty_returned,
        total_net_loss,
        total_net_paid - total_net_loss AS net_revenue,
        CASE WHEN total_qty_sold = 0 THEN 0 ELSE total_discount / total_qty_sold END AS avg_discount_per_item,
        CASE WHEN total_qty_sold = 0 THEN 0 ELSE total_qty_returned / total_qty_sold END AS return_rate,
        total_net_profit - total_net_loss AS net_profit_adj,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY (total_net_paid - total_net_loss) DESC) AS channel_rank
    FROM agg
)
SELECT
    i_category,
    i_brand,
    i_class,
    channel,
    total_qty_sold,
    total_sales,
    total_discount,
    total_qty_returned,
    total_net_loss,
    net_revenue,
    avg_discount_per_item,
    return_rate,
    net_profit_adj,
    channel_rank
FROM final_metrics
WHERE channel_rank <= 5
ORDER BY channel, channel_rank
