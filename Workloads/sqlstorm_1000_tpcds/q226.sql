WITH
sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        i.i_item_sk,
        i.i_category,
        i.i_category_id,
        i.i_brand,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount,
        cs.cs_ext_ship_cost AS ship_cost,
        cs.cs_ext_tax AS tax,
        cs.cs_coupon_amt AS coupon,
        'catalog' AS channel,
        cc.cc_name AS channel_name
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_sold_date_sk IS NOT NULL
    UNION ALL
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        i.i_item_sk,
        i.i_category,
        i.i_category_id,
        i.i_brand,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount,
        0 AS ship_cost,
        ss.ss_ext_tax AS tax,
        ss.ss_coupon_amt AS coupon,
        'store' AS channel,
        s.s_store_name AS channel_name
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        i.i_item_sk,
        i.i_category,
        i.i_category_id,
        i.i_brand,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount,
        ws.ws_ext_ship_cost AS ship_cost,
        ws.ws_ext_tax AS tax,
        ws.ws_coupon_amt AS coupon,
        'web' AS channel,
        wp.wp_url AS channel_name
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
),
returns AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        i.i_item_sk,
        i.i_category,
        i.i_category_id,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk IS NOT NULL
    UNION ALL
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        i.i_item_sk,
        i.i_category,
        i.i_category_id,
        sr.sr_return_quantity AS quantity,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss,
        'store' AS channel
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_returned_date_sk IS NOT NULL
    UNION ALL
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        i.i_item_sk,
        i.i_category,
        i.i_category_id,
        wr.wr_return_quantity AS quantity,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss,
        'web' AS channel
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_returned_date_sk IS NOT NULL
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.channel,
        s.i_category,
        s.i_brand,
        SUM(s.quantity) AS total_qty,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.discount) AS total_discount,
        SUM(s.ship_cost) AS total_ship_cost,
        SUM(s.tax) AS total_tax,
        SUM(s.coupon) AS total_coupon,
        COUNT(*) AS txn_count
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, s.channel, s.i_category, s.i_brand
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.channel,
        r.i_category,
        SUM(r.rquantity) AS total_return_qty,
        SUM(r.return_amount) AS total_return_amount,
        SUM(r.net_loss) AS total_return_loss
    FROM (
        SELECT
            r.date_sk,
            r.channel,
            r.i_category,
            r.quantity AS rquantity,
            r.return_amount,
            r.net_loss
        FROM returns r
    ) r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, r.channel, r.i_category
),
combined AS (
    SELECT
        sa.d_year,
        sa.d_month_seq,
        sa.channel,
        sa.i_category,
        sa.i_brand,
        sa.total_qty,
        sa.total_net_paid,
        sa.total_net_profit,
        sa.total_discount,
        sa.total_ship_cost,
        sa.total_tax,
        sa.total_coupon,
        sa.txn_count,
        COALESCE(ra.total_return_qty, 0) AS total_return_qty,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        (COALESCE(ra.total_return_amount, 0) / NULLIF(sa.total_net_paid, 0)) * 100 AS return_rate_pct,
        RANK() OVER (PARTITION BY sa.d_year, sa.channel ORDER BY sa.total_net_profit DESC) AS profit_rank,
        PERCENT_RANK() OVER (PARTITION BY sa.d_year, sa.channel ORDER BY sa.total_net_profit) AS profit_percentile
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.d_year = ra.d_year
        AND sa.d_month_seq = ra.d_month_seq
        AND sa.channel = ra.channel
        AND sa.i_category = ra.i_category
)
SELECT *
FROM combined
WHERE d_year BETWEEN 2001 AND 2002
  AND total_net_paid > 50000
ORDER BY d_year, d_month_seq, profit_rank
LIMIT 100
