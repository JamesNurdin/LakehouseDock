WITH
sales_union AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_order_number AS order_num,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        CAST(NULL AS integer) AS call_center_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_ticket_number AS order_num,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        CAST(NULL AS integer) AS call_center_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_order_number AS order_num,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS ext_sales_price,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        'web' AS channel
    FROM web_sales ws
),
returns_union AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_order_number AS order_num,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS quantity,
        cr.cr_net_loss AS net_loss,
        cr.cr_refunded_cash AS refunded_cash,
        'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_ticket_number AS order_num,
        sr.sr_item_sk AS item_sk,
        sr.sr_return_quantity AS quantity,
        sr.sr_net_loss AS net_loss,
        sr.sr_refunded_cash AS refunded_cash,
        'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_order_number AS order_num,
        wr.wr_item_sk AS item_sk,
        wr.wr_return_quantity AS quantity,
        wr.wr_net_loss AS net_loss,
        wr.wr_refunded_cash AS refunded_cash,
        'web' AS channel
    FROM web_returns wr
),
sales_daily AS (
    SELECT
        date_sk,
        channel,
        SUM(ext_sales_price) AS total_sales,
        SUM(net_profit) AS total_profit,
        COUNT(DISTINCT order_num) AS orders,
        COUNT(DISTINCT item_sk) AS distinct_items
    FROM sales_union
    GROUP BY date_sk, channel
),
returns_daily AS (
    SELECT
        date_sk,
        channel,
        SUM(net_loss) AS total_return_loss,
        SUM(refunded_cash) AS total_refunded_cash,
        COUNT(DISTINCT order_num) AS return_transactions
    FROM returns_union
    GROUP BY date_sk, channel
),
daily_combined AS (
    SELECT
        COALESCE(s.date_sk, r.date_sk) AS date_sk,
        COALESCE(s.channel, r.channel) AS channel,
        s.total_sales,
        s.total_profit,
        s.orders,
        s.distinct_items,
        r.total_return_loss,
        r.total_refunded_cash,
        r.return_transactions
    FROM sales_daily s
    FULL OUTER JOIN returns_daily r
        ON s.date_sk = r.date_sk AND s.channel = r.channel
),
date_enriched AS (
    SELECT
        d.d_date,
        dc.channel,
        COALESCE(dc.total_sales, 0) AS total_sales,
        COALESCE(dc.total_profit, 0) AS total_profit,
        COALESCE(dc.orders, 0) AS orders,
        COALESCE(dc.distinct_items, 0) AS distinct_items,
        COALESCE(dc.total_return_loss, 0) AS total_return_loss,
        COALESCE(dc.total_refunded_cash, 0) AS total_refunded_cash,
        COALESCE(dc.return_transactions, 0) AS return_transactions,
        CASE
            WHEN COALESCE(dc.total_sales, 0) > 0 THEN dc.total_profit / dc.total_sales
            ELSE NULL
        END AS profit_margin
    FROM daily_combined dc
    LEFT JOIN date_dim d ON dc.date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
item_metrics AS (
    SELECT
        s.channel,
        s.item_sk,
        SUM(s.ext_sales_price) AS item_sales,
        SUM(s.net_profit) AS item_profit,
        ROW_NUMBER() OVER (PARTITION BY s.channel ORDER BY SUM(s.net_profit) DESC) AS profit_rank,
        RANK() OVER (PARTITION BY s.channel ORDER BY SUM(s.ext_sales_price) DESC) AS sales_rank
    FROM sales_union s
    GROUP BY s.channel, s.item_sk
),
top_items AS (
    SELECT
        im.channel,
        im.item_sk,
        im.item_sales,
        im.item_profit,
        im.profit_rank,
        im.sales_rank,
        i.i_product_name
    FROM item_metrics im
    JOIN item i ON im.item_sk = i.i_item_sk
    WHERE im.profit_rank <= 5
),
promo_stats AS (
    SELECT
        s.channel,
        p.p_promo_name,
        COUNT(DISTINCT s.order_num) AS promo_orders,
        SUM(s.ext_sales_price) AS promo_sales,
        SUM(s.net_profit) AS promo_profit,
        MAX(p.p_discount_active) AS discount_active_flag
    FROM sales_union s
    LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
    WHERE s.promo_sk IS NOT NULL
    GROUP BY s.channel, p.p_promo_name
),
call_center_perf AS (
    SELECT
        cc.cc_name,
        cc.cc_state,
        SUM(s.ext_sales_price) AS total_sales,
        SUM(s.net_profit) AS total_profit,
        COUNT(DISTINCT s.order_num) AS total_orders
    FROM sales_union s
    JOIN call_center cc ON s.call_center_sk = cc.cc_call_center_sk
    GROUP BY cc.cc_name, cc.cc_state
),
store_only_items AS (
    SELECT DISTINCT item_sk FROM sales_union WHERE channel = 'store'
    EXCEPT
    SELECT DISTINCT item_sk FROM sales_union WHERE channel = 'web'
),
store_and_web_items AS (
    SELECT DISTINCT item_sk FROM sales_union WHERE channel = 'store'
    INTERSECT
    SELECT DISTINCT item_sk FROM sales_union WHERE channel = 'web'
),
final_report AS (
    SELECT
        de.d_date AS sales_date,
        de.channel,
        de.total_sales,
        de.total_profit,
        de.orders,
        de.distinct_items,
        de.total_return_loss,
        de.total_refunded_cash,
        de.return_transactions,
        de.profit_margin,
        (SELECT AVG(total_sales) FROM date_enriched de2 WHERE de2.channel = de.channel) AS avg_channel_sales,
        (SELECT MAX(total_sales) FROM date_enriched de3 WHERE de3.channel = de.channel) AS max_channel_sales,
        COALESCE(
            array_join(
                array_agg(CONCAT(ti.i_product_name, ':', CAST(ti.item_profit AS VARCHAR))),
                ', '
            ),
            'No top items'
        ) AS top_items_report,
        CASE WHEN de.channel = 'store' THEN (SELECT COUNT(*) FROM store_only_items) ELSE NULL END AS store_exclusive_item_count,
        CASE WHEN de.channel IN ('store','web') THEN (SELECT COUNT(*) FROM store_and_web_items) ELSE NULL END AS common_item_count
    FROM date_enriched de
    LEFT JOIN top_items ti ON de.channel = ti.channel
    GROUP BY de.d_date, de.channel, de.total_sales, de.total_profit, de.orders,
        de.distinct_items, de.total_return_loss, de.total_refunded_cash,
        de.return_transactions, de.profit_margin
)

SELECT *
FROM final_report
ORDER BY sales_date, channel
LIMIT 100
