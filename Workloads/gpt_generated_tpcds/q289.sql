WITH sales_union AS (
    -- Store channel sales net profit for the year 2000
    SELECT i.i_item_id,
           i.i_item_desc,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2000

    UNION ALL

    -- Catalog channel sales net profit for the year 2000
    SELECT i.i_item_id,
           i.i_item_desc,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2000

    UNION ALL

    -- Web channel sales net profit for the year 2000
    SELECT i.i_item_id,
           i.i_item_desc,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
),
returns_union AS (
    -- Store channel returns net loss for the year 2000
    SELECT i.i_item_id,
           i.i_item_desc,
           sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000

    UNION ALL

    -- Catalog channel returns net loss for the year 2000
    SELECT i.i_item_id,
           i.i_item_desc,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000

    UNION ALL

    -- Web channel returns net loss for the year 2000
    SELECT i.i_item_id,
           i.i_item_desc,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
),
sales_agg AS (
    SELECT i_item_id,
           i_item_desc,
           SUM(net_profit) AS total_sales_net_profit
    FROM sales_union
    GROUP BY i_item_id, i_item_desc
),
returns_agg AS (
    SELECT i_item_id,
           i_item_desc,
           SUM(net_loss) AS total_returns_net_loss
    FROM returns_union
    GROUP BY i_item_id, i_item_desc
)
SELECT sa.i_item_id,
       sa.i_item_desc,
       COALESCE(sa.total_sales_net_profit, 0) - COALESCE(ra.total_returns_net_loss, 0) AS net_profit_after_returns
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
  ON sa.i_item_id = ra.i_item_id
 AND sa.i_item_desc = ra.i_item_desc
ORDER BY net_profit_after_returns DESC
LIMIT 10
