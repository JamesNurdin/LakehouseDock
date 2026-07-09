WITH
store_sales_agg AS (
    SELECT ca.ca_state AS state,
           d.d_year AS year,
           d.d_quarter_name AS quarter,
           cd.cd_gender AS gender,
           SUM(ss.ss_net_profit) AS sales_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_state, d.d_year, d.d_quarter_name, cd.cd_gender
),
catalog_sales_agg AS (
    SELECT ca.ca_state AS state,
           d.d_year AS year,
           d.d_quarter_name AS quarter,
           cd.cd_gender AS gender,
           SUM(cs.cs_net_profit) AS sales_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_state, d.d_year, d.d_quarter_name, cd.cd_gender
),
web_sales_agg AS (
    SELECT ca.ca_state AS state,
           d.d_year AS year,
           d.d_quarter_name AS quarter,
           cd.cd_gender AS gender,
           SUM(ws.ws_net_profit) AS sales_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_state, d.d_year, d.d_quarter_name, cd.cd_gender
),
store_returns_agg AS (
    SELECT ca.ca_state AS state,
           d.d_year AS year,
           d.d_quarter_name AS quarter,
           cd.cd_gender AS gender,
           SUM(sr.sr_net_loss) AS returns_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_state, d.d_year, d.d_quarter_name, cd.cd_gender
),
catalog_returns_agg AS (
    SELECT ca.ca_state AS state,
           d.d_year AS year,
           d.d_quarter_name AS quarter,
           cd.cd_gender AS gender,
           SUM(cr.cr_net_loss) AS returns_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_state, d.d_year, d.d_quarter_name, cd.cd_gender
),
web_returns_agg AS (
    SELECT ca.ca_state AS state,
           d.d_year AS year,
           d.d_quarter_name AS quarter,
           cd.cd_gender AS gender,
           SUM(wr.wr_net_loss) AS returns_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_state, d.d_year, d.d_quarter_name, cd.cd_gender
),
sales_all AS (
    SELECT state, year, quarter, gender, sales_profit FROM store_sales_agg
    UNION ALL
    SELECT state, year, quarter, gender, sales_profit FROM catalog_sales_agg
    UNION ALL
    SELECT state, year, quarter, gender, sales_profit FROM web_sales_agg
),
returns_all AS (
    SELECT state, year, quarter, gender, returns_loss FROM store_returns_agg
    UNION ALL
    SELECT state, year, quarter, gender, returns_loss FROM catalog_returns_agg
    UNION ALL
    SELECT state, year, quarter, gender, returns_loss FROM web_returns_agg
),
sales_summary AS (
    SELECT state,
           year,
           quarter,
           gender,
           SUM(sales_profit) AS total_sales_profit
    FROM sales_all
    GROUP BY state, year, quarter, gender
),
returns_summary AS (
    SELECT state,
           year,
           quarter,
           gender,
           SUM(returns_loss) AS total_returns_loss
    FROM returns_all
    GROUP BY state, year, quarter, gender
),
final AS (
    SELECT s.state,
           s.year,
           s.quarter,
           s.gender,
           s.total_sales_profit,
           COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
           s.total_sales_profit - COALESCE(r.total_returns_loss, 0) AS net_profit,
           CASE WHEN COALESCE(r.total_returns_loss, 0) = 0 THEN NULL
                ELSE s.total_sales_profit / COALESCE(r.total_returns_loss, 0) END AS profit_to_loss_ratio
    FROM sales_summary s
    LEFT JOIN returns_summary r
      ON s.state = r.state
     AND s.year = r.year
     AND s.quarter = r.quarter
     AND s.gender = r.gender
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY year ORDER BY net_profit DESC) AS profit_rank_year
    FROM final
    WHERE net_profit > 0
)
SELECT state,
       year,
       quarter,
       gender,
       total_sales_profit,
       total_returns_loss,
       net_profit,
       profit_to_loss_ratio,
       profit_rank_year
FROM ranked
ORDER BY net_profit DESC
LIMIT 200
