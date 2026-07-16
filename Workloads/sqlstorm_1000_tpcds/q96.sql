WITH sales_agg AS (
    SELECT
        us.item_sk,
        us.state,
        us.sales_year,
        us.sales_month_seq,
        us.channel,
        SUM(us.qty) AS total_qty_sold,
        SUM(us.net_profit) AS total_net_profit,
        COUNT(DISTINCT us.location_sk) AS distinct_locations
    FROM (
        SELECT
            ss.ss_item_sk AS item_sk,
            s.s_state AS state,
            d.d_year AS sales_year,
            d.d_month_seq AS sales_month_seq,
            ss.ss_quantity AS qty,
            ss.ss_net_profit AS net_profit,
            ss.ss_store_sk AS location_sk,
            'store' AS channel
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        UNION ALL
        SELECT
            cs.cs_item_sk,
            cc.cc_state,
            d.d_year,
            d.d_month_seq,
            cs.cs_quantity,
            cs.cs_net_profit,
            cs.cs_call_center_sk,
            'catalog'
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        UNION ALL
        SELECT
            ws.ws_item_sk,
            w.web_state,
            d.d_year,
            d.d_month_seq,
            ws.ws_quantity,
            ws.ws_net_profit,
            ws.ws_web_site_sk,
            'web'
        FROM web_sales ws
        JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    ) us
    GROUP BY us.item_sk, us.state, us.sales_year, us.sales_month_seq, us.channel
),
returns_agg AS (
    SELECT
        ur.item_sk,
        ur.sales_year,
        ur.sales_month_seq,
        ur.channel,
        SUM(ur.return_quantity) AS total_qty_returned,
        SUM(ur.return_amount) AS total_return_amount,
        SUM(ur.return_tax) AS total_return_tax
    FROM (
        SELECT
            cr.cr_item_sk AS item_sk,
            cr.cr_return_quantity AS return_quantity,
            cr.cr_return_amount AS return_amount,
            cr.cr_return_tax AS return_tax,
            d.d_year AS sales_year,
            d.d_month_seq AS sales_month_seq,
            'catalog' AS channel
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        UNION ALL
        SELECT
            sr.sr_item_sk,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_return_tax,
            d.d_year,
            d.d_month_seq,
            'store'
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        UNION ALL
        SELECT
            wr.wr_item_sk,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            wr.wr_return_tax,
            d.d_year,
            d.d_month_seq,
            'web'
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    ) ur
    GROUP BY ur.item_sk, ur.sales_year, ur.sales_month_seq, ur.channel
),
joined AS (
    SELECT
        sa.item_sk,
        i.i_category,
        i.i_brand,
        sa.state,
        sa.sales_year,
        sa.sales_month_seq,
        sa.channel,
        sa.total_qty_sold,
        sa.total_net_profit,
        sa.distinct_locations,
        COALESCE(ra.total_qty_returned, 0) AS total_qty_returned,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        COALESCE(ra.total_return_tax, 0) AS total_return_tax
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.item_sk = ra.item_sk
        AND sa.sales_year = ra.sales_year
        AND sa.sales_month_seq = ra.sales_month_seq
        AND sa.channel = ra.channel
    JOIN item i ON i.i_item_sk = sa.item_sk
    WHERE sa.sales_year BETWEEN 2000 AND 2002
)
SELECT
    i_category,
    i_brand,
    state,
    sales_year,
    sales_month_seq,
    channel,
    total_qty_sold,
    total_net_profit,
    total_qty_returned,
    total_return_amount,
    total_return_tax,
    distinct_locations,
    RANK() OVER (PARTITION BY sales_year, channel ORDER BY total_net_profit DESC) AS profit_rank
FROM joined
ORDER BY total_net_profit DESC
LIMIT 200
