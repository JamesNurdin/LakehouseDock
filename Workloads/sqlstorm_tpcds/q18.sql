WITH date_filtered AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
store_sales_agg AS (
    SELECT
        d.d_date AS sales_date,
        'store' AS channel,
        s.s_store_sk AS entity_sk,
        s.s_store_id AS entity_id_str,
        CONCAT(s.s_city, ', ', s.s_state) AS entity_desc,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_coupon_amt) AS avg_coupon_amt,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        COALESCE(SUM(ss.ss_ext_discount_amt), 0) AS total_discount
    FROM store_sales ss
    JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_quantity > 0
    GROUP BY d.d_date, s.s_store_sk, s.s_store_id, s.s_city, s.s_state
),
catalog_sales_agg AS (
    SELECT
        d.d_date AS sales_date,
        'catalog' AS channel,
        cp.cp_catalog_page_sk AS entity_sk,
        cp.cp_catalog_page_id AS entity_id_str,
        cp.cp_department AS entity_desc,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_coupon_amt) AS avg_coupon_amt,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        COALESCE(SUM(cs.cs_ext_discount_amt), 0) AS total_discount
    FROM catalog_sales cs
    JOIN date_filtered d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_quantity > 0
    GROUP BY d.d_date, cp.cp_catalog_page_sk, cp.cp_catalog_page_id, cp.cp_department
),
web_sales_agg AS (
    SELECT
        d.d_date AS sales_date,
        'web' AS channel,
        wp.wp_web_page_sk AS entity_sk,
        wp.wp_web_page_id AS entity_id_str,
        wp.wp_type AS entity_desc,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_coupon_amt) AS avg_coupon_amt,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        COALESCE(SUM(ws.ws_ext_discount_amt), 0) AS total_discount
    FROM web_sales ws
    JOIN date_filtered d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_quantity > 0
    GROUP BY d.d_date, wp.wp_web_page_sk, wp.wp_web_page_id, wp.wp_type
),
store_returns_agg AS (
    SELECT
        d.d_date AS return_date,
        'store' AS channel,
        sr.sr_store_sk AS entity_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_orders
    FROM store_returns sr
    JOIN date_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, sr.sr_store_sk
),
catalog_returns_agg AS (
    SELECT
        d.d_date AS return_date,
        'catalog' AS channel,
        cr.cr_catalog_page_sk AS entity_sk,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders
    FROM catalog_returns cr
    JOIN date_filtered d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, cr.cr_catalog_page_sk
),
web_returns_agg AS (
    SELECT
        d.d_date AS return_date,
        'web' AS channel,
        wr.wr_web_page_sk AS entity_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT wr.wr_order_number) AS return_orders
    FROM web_returns wr
    JOIN date_filtered d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, wr.wr_web_page_sk
),
combined_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
combined_returns AS (
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
),
sales_with_returns AS (
    SELECT
        s.sales_date,
        s.channel,
        s.entity_sk,
        s.entity_id_str,
        s.entity_desc,
        s.total_sales,
        s.total_profit,
        s.avg_coupon_amt,
        s.total_quantity,
        s.orders,
        s.total_discount,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_return_qty, 0) AS total_return_qty,
        COALESCE(r.return_orders, 0) AS return_orders,
        CASE WHEN s.total_sales > 0 THEN COALESCE(r.total_return_amount, 0) / s.total_sales END AS return_rate_amount,
        CASE WHEN s.total_quantity > 0 THEN COALESCE(r.total_return_qty, 0) / s.total_quantity END AS return_rate_quantity,
        (SELECT AVG(s2.total_sales)
           FROM combined_sales s2
           WHERE s2.channel = s.channel
             AND s2.sales_date BETWEEN s.sales_date - INTERVAL '7' DAY AND s.sales_date - INTERVAL '1' DAY
             AND s2.entity_sk = s.entity_sk) AS avg_sales_last_7d,
        CONCAT(s.entity_id_str, ':', s.entity_desc) AS entity_label
    FROM combined_sales s
    LEFT JOIN combined_returns r
      ON r.channel = s.channel
     AND r.return_date = s.sales_date
     AND r.entity_sk = s.entity_sk
),
ranked_entities AS (
    SELECT
        sales_date,
        channel,
        entity_label,
        total_sales,
        total_profit,
        avg_coupon_amt,
        total_quantity,
        orders,
        total_discount,
        total_return_amount,
        total_return_qty,
        return_orders,
        return_rate_amount,
        return_rate_quantity,
        avg_sales_last_7d,
        ROW_NUMBER() OVER (PARTITION BY sales_date, channel ORDER BY total_profit DESC) AS profit_rank,
        SUM(total_sales) OVER (PARTITION BY sales_date, channel) AS channel_daily_sales,
        SUM(total_profit) OVER (PARTITION BY sales_date, channel) AS channel_daily_profit,
        AVG(return_rate_amount) OVER (PARTITION BY channel) AS avg_return_rate_amount_channel
    FROM sales_with_returns
)
SELECT
    sales_date,
    channel,
    entity_label,
    total_sales,
    total_profit,
    profit_rank,
    return_rate_amount,
    return_rate_quantity,
    avg_sales_last_7d,
    channel_daily_sales,
    channel_daily_profit,
    avg_return_rate_amount_channel
FROM ranked_entities
WHERE profit_rank <= 5
ORDER BY sales_date DESC, channel, profit_rank
