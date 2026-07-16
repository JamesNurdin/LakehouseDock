WITH sales_agg AS (
    SELECT
        CAST('store' AS varchar) AS channel,
        ss.ss_item_sk AS item_sk,
        ss.ss_sold_date_sk AS date_sk,
        s.s_store_id AS store_id,
        CAST(NULL AS varchar) AS catalog_page_id,
        CAST(NULL AS varchar) AS web_page_id,
        CAST(NULL AS varchar) AS call_center_name,
        i.i_product_name AS product_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid_inc_tax) AS total_revenue,
        SUM(ss.ss_net_profit) AS total_profit,
        CAST(SUM(ss.ss_quantity) AS decimal(15,2)) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk, s.s_store_id, i.i_product_name, d.d_year, d.d_month_seq
), catalog_agg AS (
    SELECT
        CAST('catalog' AS varchar) AS channel,
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS date_sk,
        CAST(NULL AS varchar) AS store_id,
        cp.cp_catalog_page_id AS catalog_page_id,
        CAST(NULL AS varchar) AS web_page_id,
        cc.cc_name AS call_center_name,
        i.i_product_name AS product_name,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid_inc_tax) AS total_revenue,
        SUM(cs.cs_net_profit) AS total_profit,
        CAST(SUM(cs.cs_quantity) AS decimal(15,2)) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk, cp.cp_catalog_page_id, cc.cc_name, i.i_product_name, d.d_year, d.d_month_seq
), web_agg AS (
    SELECT
        CAST('web' AS varchar) AS channel,
        ws.ws_item_sk AS item_sk,
        ws.ws_sold_date_sk AS date_sk,
        CAST(NULL AS varchar) AS store_id,
        CAST(NULL AS varchar) AS catalog_page_id,
        wp.wp_web_page_id AS web_page_id,
        CAST(NULL AS varchar) AS call_center_name,
        i.i_product_name AS product_name,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        SUM(ws.ws_net_profit) AS total_profit,
        CAST(SUM(ws.ws_quantity) AS decimal(15,2)) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk, wp.wp_web_page_id, i.i_product_name, d.d_year, d.d_month_seq
), returns_agg AS (
    SELECT
        CAST('store' AS varchar) AS channel,
        sr.sr_item_sk AS item_sk,
        sr.sr_returned_date_sk AS date_sk,
        SUM(sr.sr_return_quantity) AS return_quantity,
        SUM(sr.sr_return_amt) AS return_amount
    FROM store_returns sr
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
    UNION ALL
    SELECT
        CAST('catalog' AS varchar) AS channel,
        cr.cr_item_sk AS item_sk,
        cr.cr_returned_date_sk AS date_sk,
        SUM(cr.cr_return_quantity) AS return_quantity,
        SUM(cr.cr_return_amount) AS return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk
    UNION ALL
    SELECT
        CAST('web' AS varchar) AS channel,
        wr.wr_item_sk AS item_sk,
        wr.wr_returned_date_sk AS date_sk,
        SUM(wr.wr_return_quantity) AS return_quantity,
        SUM(wr.wr_return_amt) AS return_amount
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk
), combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    c.channel,
    c.item_sk,
    c.product_name,
    c.store_id,
    c.catalog_page_id,
    c.web_page_id,
    c.call_center_name,
    c.d_year,
    c.d_month_seq,
    c.total_revenue,
    c.total_profit,
    c.total_quantity,
    COALESCE(r.return_quantity, 0) AS return_quantity,
    COALESCE(r.return_amount, 0) AS return_amount,
    CASE WHEN c.total_quantity > 0 THEN COALESCE(r.return_quantity, 0) / c.total_quantity ELSE 0 END AS return_rate,
    RANK() OVER (PARTITION BY c.channel, c.d_year, c.d_month_seq ORDER BY c.total_profit DESC) AS profit_rank
FROM combined c
LEFT JOIN returns_agg r
    ON c.channel = r.channel
    AND c.item_sk = r.item_sk
    AND c.date_sk = r.date_sk
ORDER BY c.channel, c.d_year, c.d_month_seq, profit_rank
LIMIT 100
