WITH all_sales AS (
    SELECT
        ss_item_sk AS item_sk,
        ss_sold_date_sk AS date_sk,
        ss_quantity AS quantity,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        'store' AS channel,
        ss_store_sk AS store_sk,
        ss_customer_sk AS customer_sk
    FROM store_sales
    UNION ALL
    SELECT
        cs_item_sk AS item_sk,
        cs_sold_date_sk AS date_sk,
        cs_quantity AS quantity,
        cs_net_paid AS net_paid,
        cs_net_profit AS net_profit,
        'catalog' AS channel,
        cs_call_center_sk AS store_sk,
        cs_bill_customer_sk AS customer_sk
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_item_sk AS item_sk,
        ws_sold_date_sk AS date_sk,
        ws_quantity AS quantity,
        ws_net_paid AS net_paid,
        ws_net_profit AS net_profit,
        'web' AS channel,
        ws_warehouse_sk AS store_sk,
        ws_bill_customer_sk AS customer_sk
    FROM web_sales
),
item_sales_agg AS (
    SELECT
        a.item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        i.i_color,
        d.d_date,
        a.date_sk,
        a.channel,
        SUM(a.quantity) AS total_quantity,
        SUM(a.net_paid) AS total_net_paid,
        SUM(a.net_profit) AS total_net_profit
    FROM all_sales a
    LEFT JOIN item i ON a.item_sk = i.i_item_sk
    LEFT JOIN date_dim d ON a.date_sk = d.d_date_sk
    GROUP BY
        a.item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        i.i_color,
        d.d_date,
        a.date_sk,
        a.channel
),
daily_window AS (
    SELECT
        *,
        SUM(total_net_profit) OVER (
            PARTITION BY item_sk, channel
            ORDER BY date_sk
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS profit_7day_sum,
        ROW_NUMBER() OVER (
            PARTITION BY date_sk, channel
            ORDER BY total_net_profit DESC
        ) AS daily_channel_rank
    FROM item_sales_agg
),
top_items AS (
    SELECT
        dw.item_sk,
        dw.i_item_id,
        dw.i_item_desc,
        dw.i_brand,
        dw.i_category,
        dw.i_color,
        dw.date_sk,
        dw.d_date,
        dw.channel,
        dw.total_quantity,
        dw.total_net_paid,
        dw.total_net_profit,
        dw.profit_7day_sum,
        dw.daily_channel_rank,
        CONCAT(dw.i_item_id, '-', CAST(dw.d_date AS VARCHAR), '-', dw.channel) AS report_key
    FROM daily_window dw
    WHERE dw.daily_channel_rank <= 5
),
returns_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_returned_date_sk AS date_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk
    UNION ALL
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_quantity),
        SUM(sr.sr_return_amt),
        SUM(sr.sr_fee),
        SUM(sr.sr_net_loss)
    FROM store_returns sr
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
    UNION ALL
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_quantity),
        SUM(wr.wr_return_amt),
        SUM(wr.wr_fee),
        SUM(wr.wr_net_loss)
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk
),
final AS (
    SELECT
        ti.report_key,
        ti.i_item_id,
        ti.i_item_desc,
        ti.i_brand,
        ti.i_category,
        ti.i_color,
        ti.d_date,
        ti.channel,
        ti.total_quantity,
        ti.total_net_paid,
        ti.total_net_profit,
        ti.profit_7day_sum,
        ti.daily_channel_rank,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_fee, 0) AS total_fee,
        COALESCE(r.total_net_loss, 0) AS total_net_loss,
        (ti.total_net_profit - COALESCE(r.total_net_loss, 0)) AS adjusted_net_profit,
        CASE
            WHEN ti.total_net_profit = 0 THEN NULL
            ELSE (ti.total_net_profit - COALESCE(r.total_net_loss, 0)) / ti.total_net_profit
        END AS profit_loss_ratio
    FROM top_items ti
    LEFT JOIN returns_agg r
        ON ti.item_sk = r.item_sk
        AND ti.date_sk = r.date_sk
)
SELECT *
FROM final
WHERE profit_loss_ratio IS NOT NULL
ORDER BY d_date DESC, channel, profit_loss_ratio DESC
LIMIT 100
