WITH sales_agg AS (
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           i.i_category AS category,
           sum(cs.cs_net_profit) AS sales_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, ca.ca_state, i.i_category
    UNION ALL
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           i.i_category AS category,
           sum(ss.ss_net_profit) AS sales_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, ca.ca_state, i.i_category
    UNION ALL
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           i.i_category AS category,
           sum(ws.ws_net_profit) AS sales_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, ca.ca_state, i.i_category
), sales_total AS (
    SELECT year, state, category, sum(sales_profit) AS total_sales_profit
    FROM sales_agg
    GROUP BY year, state, category
), returns_agg AS (
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           i.i_category AS category,
           sum(cr.cr_net_loss) AS return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, ca.ca_state, i.i_category
    UNION ALL
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           i.i_category AS category,
           sum(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, ca.ca_state, i.i_category
    UNION ALL
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           i.i_category AS category,
           sum(wr.wr_net_loss) AS return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, ca.ca_state, i.i_category
), returns_total AS (
    SELECT year, state, category, sum(return_loss) AS total_return_loss
    FROM returns_agg
    GROUP BY year, state, category
), profit AS (
    SELECT s.year,
           s.state,
           s.category,
           s.total_sales_profit - coalesce(r.total_return_loss, 0) AS total_profit
    FROM sales_total s
    LEFT JOIN returns_total r
      ON s.year = r.year AND s.state = r.state AND s.category = r.category
)
SELECT
    year,
    state,
    category,
    total_profit,
    row_number() OVER (PARTITION BY state ORDER BY total_profit DESC) AS state_category_rank,
    avg(total_profit) OVER (PARTITION BY state, category ORDER BY year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3yr
FROM profit
ORDER BY total_profit DESC
LIMIT 200
