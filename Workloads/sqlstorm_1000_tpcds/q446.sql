WITH sales AS (
    SELECT 'store' AS channel,
        s.s_state AS state,
        d.d_year AS year,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_sales_price AS ext_sales,
        CAST(0 AS decimal(7,2)) AS net_loss,
        ss.ss_quantity AS quantity,
        CAST(0 AS integer) AS return_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    UNION ALL
    SELECT 'catalog' AS channel,
        cc.cc_state AS state,
        d.d_year AS year,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_sales_price AS ext_sales,
        CAST(0 AS decimal(7,2)) AS net_loss,
        cs.cs_quantity AS quantity,
        CAST(0 AS integer) AS return_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    UNION ALL
    SELECT 'web' AS channel,
        w.web_state AS state,
        d.d_year AS year,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_sales_price AS ext_sales,
        CAST(0 AS decimal(7,2)) AS net_loss,
        ws.ws_quantity AS quantity,
        CAST(0 AS integer) AS return_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
),
returns AS (
    SELECT 'store' AS channel,
        s.s_state AS state,
        d.d_year AS year,
        CAST(0 AS decimal(7,2)) AS net_paid,
        CAST(0 AS decimal(7,2)) AS net_profit,
        CAST(0 AS decimal(7,2)) AS ext_sales,
        sr.sr_net_loss AS net_loss,
        CAST(0 AS integer) AS quantity,
        sr.sr_return_quantity AS return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    UNION ALL
    SELECT 'catalog' AS channel,
        cc.cc_state AS state,
        d.d_year AS year,
        CAST(0 AS decimal(7,2)) AS net_paid,
        CAST(0 AS decimal(7,2)) AS net_profit,
        CAST(0 AS decimal(7,2)) AS ext_sales,
        cr.cr_net_loss AS net_loss,
        CAST(0 AS integer) AS quantity,
        cr.cr_return_quantity AS return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    UNION ALL
    SELECT 'web' AS channel,
        'UNKNOWN' AS state,
        d.d_year AS year,
        CAST(0 AS decimal(7,2)) AS net_paid,
        CAST(0 AS decimal(7,2)) AS net_profit,
        CAST(0 AS decimal(7,2)) AS ext_sales,
        wr.wr_net_loss AS net_loss,
        CAST(0 AS integer) AS quantity,
        wr.wr_return_quantity AS return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),
combined AS (
    SELECT
        channel,
        state,
        year,
        sum(net_paid) AS total_net_paid,
        sum(net_profit) AS total_net_profit,
        sum(ext_sales) AS total_ext_sales,
        sum(net_loss) AS total_net_loss,
        sum(quantity) AS total_quantity,
        sum(return_quantity) AS total_return_quantity
    FROM (
        SELECT * FROM sales
        UNION ALL
        SELECT * FROM returns
    ) u
    GROUP BY ROLLUP (channel, state, year)
)
SELECT
    channel,
    state,
    year,
    total_net_paid,
    total_net_profit,
    total_net_loss,
    total_ext_sales,
    total_quantity,
    total_return_quantity,
    total_net_profit - total_net_loss AS net_contribution,
    row_number() OVER (PARTITION BY channel ORDER BY total_net_paid DESC) AS net_paid_rank,
    rank() OVER (PARTITION BY channel ORDER BY total_net_profit DESC) AS profit_rank,
    percent_rank() OVER (PARTITION BY channel ORDER BY total_net_paid) AS net_paid_pct_rank
FROM combined
WHERE year BETWEEN 1998 AND 2002
ORDER BY channel, net_contribution DESC
LIMIT 200
