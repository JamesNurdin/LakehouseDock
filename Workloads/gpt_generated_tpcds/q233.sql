WITH store_sales_agg AS (
    SELECT d.d_year AS d_year,
           sum(ss.ss_net_profit) AS total_store_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year
),
web_sales_agg AS (
    SELECT d.d_year AS d_year,
           sum(ws.ws_net_profit) AS total_web_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year
),
web_returns_agg AS (
    SELECT d.d_year AS d_year,
           sum(wr.wr_net_loss) AS total_web_returns_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year
),
call_center_agg AS (
    SELECT d.d_year AS d_year,
           count(distinct cc.cc_call_center_sk) AS call_centers_opened
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year
),
catalog_page_agg AS (
    SELECT d.d_year AS d_year,
           count(distinct cp.cp_catalog_page_sk) AS catalog_pages_started
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year
)
SELECT coalesce(s.d_year, w.d_year, r.d_year, cc.d_year, cp.d_year) AS d_year,
       coalesce(s.total_store_net_profit, 0) AS total_store_net_profit,
       coalesce(w.total_web_net_profit, 0) AS total_web_net_profit,
       coalesce(r.total_web_returns_net_loss, 0) AS total_web_returns_net_loss,
       coalesce(cc.call_centers_opened, 0) AS call_centers_opened,
       coalesce(cp.catalog_pages_started, 0) AS catalog_pages_started
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w ON s.d_year = w.d_year
FULL OUTER JOIN web_returns_agg r ON coalesce(s.d_year, w.d_year) = r.d_year
FULL OUTER JOIN call_center_agg cc ON coalesce(s.d_year, w.d_year, r.d_year) = cc.d_year
FULL OUTER JOIN catalog_page_agg cp ON coalesce(s.d_year, w.d_year, r.d_year, cc.d_year) = cp.d_year
ORDER BY d_year
