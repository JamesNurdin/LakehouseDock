WITH sales_raw AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           i.i_category,
           cs.cs_ext_sales_price AS ext_sales_price,
           cs.cs_net_profit AS net_profit,
           cc.cc_state AS state,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_sold_date_sk IS NOT NULL
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           i.i_category,
           ss.ss_ext_sales_price,
           ss.ss_net_profit,
           s.s_state,
           'store'
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           i.i_category,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           ws_site.web_state,
           'web'
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
),
returns_raw AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           i.i_category,
           cr.cr_net_loss AS net_loss,
           cc.cc_state AS state,
           'catalog' AS channel
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_returned_date_sk IS NOT NULL
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           i.i_category,
           sr.sr_net_loss,
           s.s_state,
           'store'
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_returned_date_sk IS NOT NULL
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           i.i_category,
           wr.wr_net_loss,
           NULL,
           'web'
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_returned_date_sk IS NOT NULL
),
sales_agg AS (
    SELECT d.d_year,
           s.channel,
           s.i_category,
           s.state,
           SUM(s.ext_sales_price) AS total_sales,
           SUM(s.net_profit) AS total_profit
    FROM sales_raw s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY d.d_year, s.channel, s.i_category, s.state
),
returns_agg AS (
    SELECT d.d_year,
           r.channel,
           r.i_category,
           r.state,
           SUM(r.net_loss) AS total_return_loss
    FROM returns_raw r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    GROUP BY d.d_year, r.channel, r.i_category, r.state
)
SELECT final.d_year,
       final.channel,
       final.i_category,
       final.state,
       final.total_sales,
       final.total_profit,
       final.total_return_loss,
       final.net_revenue,
       final.sales_rank
FROM (
    SELECT agg.d_year,
           agg.channel,
           agg.i_category,
           COALESCE(agg.state, 'ALL') AS state,
           agg.total_sales,
           agg.total_profit,
           COALESCE(ret.total_return_loss, 0) AS total_return_loss,
           agg.total_sales - COALESCE(ret.total_return_loss, 0) AS net_revenue,
           ROW_NUMBER() OVER (PARTITION BY agg.d_year, agg.channel ORDER BY agg.total_sales DESC) AS sales_rank
    FROM sales_agg agg
    LEFT JOIN returns_agg ret
        ON agg.d_year = ret.d_year
        AND agg.channel = ret.channel
        AND agg.i_category = ret.i_category
        AND (agg.state = ret.state OR (agg.state IS NULL AND ret.state IS NULL))
    WHERE agg.total_sales > 100000
) final
WHERE final.sales_rank <= 10
ORDER BY final.d_year DESC, final.channel, final.net_revenue DESC
LIMIT 100
