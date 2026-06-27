WITH combined AS (
    -- Store sales (net profit) for 2001
    SELECT i.i_category,
           i.i_class,
           ss.ss_net_profit AS total_sales_net_profit,
           CAST(0 AS decimal(7,2)) AS total_returns_net_loss
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001

    UNION ALL

    -- Store returns (net loss) for 2001
    SELECT i.i_category,
           i.i_class,
           CAST(0 AS decimal(7,2)) AS total_sales_net_profit,
           sr.sr_net_loss AS total_returns_net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001

    UNION ALL

    -- Catalog sales (net profit) for 2001
    SELECT i.i_category,
           i.i_class,
           cs.cs_net_profit AS total_sales_net_profit,
           CAST(0 AS decimal(7,2)) AS total_returns_net_loss
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001

    UNION ALL

    -- Catalog returns (net loss) for 2001
    SELECT i.i_category,
           i.i_class,
           CAST(0 AS decimal(7,2)) AS total_sales_net_profit,
           cr.cr_net_loss AS total_returns_net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001

    UNION ALL

    -- Web sales (net profit) for 2001
    SELECT i.i_category,
           i.i_class,
           ws.ws_net_profit AS total_sales_net_profit,
           CAST(0 AS decimal(7,2)) AS total_returns_net_loss
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001

    UNION ALL

    -- Web returns (net loss) for 2001
    SELECT i.i_category,
           i.i_class,
           CAST(0 AS decimal(7,2)) AS total_sales_net_profit,
           wr.wr_net_loss AS total_returns_net_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT combined.i_category,
       combined.i_class,
       SUM(combined.total_sales_net_profit) AS total_sales_profit,
       SUM(combined.total_returns_net_loss) AS total_returns_loss,
       (SUM(combined.total_sales_net_profit) - SUM(combined.total_returns_net_loss)) AS net_profit
FROM combined
GROUP BY combined.i_category, combined.i_class
ORDER BY net_profit DESC
LIMIT 10
