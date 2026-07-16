WITH sales_agg AS (
    SELECT i.i_category AS i_category,
           sum(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category

    UNION ALL

    SELECT i.i_category AS i_category,
           sum(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category

    UNION ALL

    SELECT i.i_category AS i_category,
           sum(ws.ws_net_profit) AS total_sales_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category
),
sales_total AS (
    SELECT i_category,
           sum(total_sales_profit) AS total_sales_profit
    FROM sales_agg
    GROUP BY i_category
),
returns_agg AS (
    SELECT i.i_category AS i_category,
           sum(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category

    UNION ALL

    SELECT i.i_category AS i_category,
           sum(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category

    UNION ALL

    SELECT i.i_category AS i_category,
           sum(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category
),
returns_total AS (
    SELECT i_category,
           sum(total_return_loss) AS total_return_loss
    FROM returns_agg
    GROUP BY i_category
)
SELECT s.i_category,
       s.total_sales_profit,
       coalesce(r.total_return_loss, 0) AS total_return_loss,
       s.total_sales_profit - coalesce(r.total_return_loss, 0) AS net_profit
FROM sales_total s
LEFT JOIN returns_total r
  ON s.i_category = r.i_category
ORDER BY net_profit DESC
LIMIT 20
