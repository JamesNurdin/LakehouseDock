WITH all_sales AS (
    -- Combine catalog and web sales, preserving the same dimensional columns
    SELECT i.i_category AS category,
           d.d_year    AS year,
           d.d_month_seq AS month_seq,
           sm.sm_type AS ship_type,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000
    UNION ALL
    SELECT i.i_category AS category,
           d.d_year    AS year,
           d.d_month_seq AS month_seq,
           sm.sm_type AS ship_type,
           ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000
),
sales_agg AS (
    -- Aggregate profit from both channels by category, month and ship type
    SELECT category,
           year,
           month_seq,
           ship_type,
           SUM(profit) AS sales_profit
    FROM all_sales
    GROUP BY category, year, month_seq, ship_type
),
returns_agg AS (
    -- Aggregate return losses (catalog only) by the same dimensions
    SELECT i.i_category AS category,
           d.d_year    AS year,
           d.d_month_seq AS month_seq,
           sm.sm_type AS ship_type,
           SUM(cr.cr_net_loss) AS returns_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, d.d_year, d.d_month_seq, sm.sm_type
)
SELECT s.category,
       s.year,
       s.month_seq,
       s.ship_type,
       s.sales_profit - COALESCE(r.returns_loss, 0) AS net_profit
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.category = r.category
 AND s.year = r.year
 AND s.month_seq = r.month_seq
 AND s.ship_type = r.ship_type
ORDER BY net_profit DESC
LIMIT 20
