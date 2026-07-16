WITH
sales_raw AS (
   SELECT d.d_year AS yr,
          cc.cc_state AS state,
          cs.cs_ext_sales_price AS total_sales,
          cs.cs_net_profit AS total_profit
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   UNION ALL
   SELECT d.d_year AS yr,
          s.s_state AS state,
          ss.ss_ext_sales_price AS total_sales,
          ss.ss_net_profit AS total_profit
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   UNION ALL
   SELECT d.d_year AS yr,
          wsite.web_state AS state,
          ws.ws_ext_sales_price AS total_sales,
          ws.ws_net_profit AS total_profit
   FROM web_sales ws
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
sales_agg AS (
   SELECT yr,
          state,
          sum(total_sales) AS total_sales,
          sum(total_profit) AS total_profit
   FROM sales_raw
   GROUP BY yr, state
),
returns_raw AS (
   SELECT d.d_year AS yr,
          cc.cc_state AS state,
          cr.cr_net_loss AS total_loss
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   UNION ALL
   SELECT d.d_year AS yr,
          s.s_state AS state,
          sr.sr_net_loss AS total_loss
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   UNION ALL
   SELECT d.d_year AS yr,
          wsite.web_state AS state,
          wr.wr_net_loss AS total_loss
   FROM web_returns wr
   LEFT JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
   LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),
returns_agg AS (
   SELECT yr,
          state,
          sum(total_loss) AS total_loss
   FROM returns_raw
   GROUP BY yr, state
),
combined AS (
   SELECT
       COALESCE(s.yr, r.yr) AS yr,
       COALESCE(s.state, r.state) AS state,
       COALESCE(s.total_sales, 0) AS total_sales,
       COALESCE(s.total_profit, 0) AS total_profit,
       COALESCE(r.total_loss, 0) AS total_loss
   FROM sales_agg s
   FULL OUTER JOIN returns_agg r
     ON s.yr = r.yr AND s.state = r.state
)
SELECT
    yr AS year,
    state,
    total_sales,
    total_profit,
    total_loss,
    (total_profit - total_loss) AS net_profit,
    rank() OVER (PARTITION BY yr ORDER BY (total_profit - total_loss) DESC) AS profit_rank
FROM combined
WHERE yr BETWEEN 1999 AND 2001
ORDER BY yr, profit_rank
LIMIT 100
