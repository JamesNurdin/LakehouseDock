WITH union_sales AS (
    SELECT
        s.s_state AS state,
        d.d_year AS yr,
        'store' AS channel,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS net_profit,
        0.0 AS returns_loss,
        ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        s.s_state AS state,
        d.d_year AS yr,
        'store' AS channel,
        0.0 AS sales_amount,
        0.0 AS net_profit,
        sr.sr_net_loss AS returns_loss,
        -sr.sr_return_quantity AS quantity
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        cc.cc_state AS state,
        d.d_year AS yr,
        'catalog' AS channel,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS net_profit,
        0.0 AS returns_loss,
        cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        cc.cc_state AS state,
        d.d_year AS yr,
        'catalog' AS channel,
        0.0 AS sales_amount,
        0.0 AS net_profit,
        cr.cr_net_loss AS returns_loss,
        -cr.cr_return_quantity AS quantity
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        w.web_state AS state,
        d.d_year AS yr,
        'web' AS channel,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS net_profit,
        0.0 AS returns_loss,
        ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        w.web_state AS state,
        d.d_year AS yr,
        'web' AS channel,
        0.0 AS sales_amount,
        0.0 AS net_profit,
        wr.wr_net_loss AS returns_loss,
        -wr.wr_return_quantity AS quantity
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
agg AS (
    SELECT
        state,
        yr,
        channel,
        SUM(sales_amount) AS sales_amount,
        SUM(net_profit) AS net_profit,
        SUM(returns_loss) AS returns_loss,
        SUM(quantity) AS total_quantity,
        SUM(net_profit) - SUM(returns_loss) AS net_profit_after_returns
    FROM union_sales
    GROUP BY state, yr, channel
    HAVING SUM(sales_amount) > 10000
)
SELECT
    state,
    yr,
    channel,
    sales_amount,
    net_profit,
    returns_loss,
    total_quantity,
    net_profit_after_returns,
    RANK() OVER (PARTITION BY yr ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM agg
ORDER BY yr, profit_rank
LIMIT 200
