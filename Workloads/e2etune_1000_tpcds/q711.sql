WITH filtered_sales AS (
    SELECT ws.ws_order_number,
           ws.ws_item_sk,
           ws.ws_web_site_sk AS site_sk,
           ws.ws_net_paid,
           ws.ws_sold_time_sk
    FROM web_sales ws
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_meal_time = 'breakfast'
      AND td.t_am_pm = 'AM'
),
sales_agg AS (
    SELECT site_sk,
           SUM(ws_net_paid) AS total_sales
    FROM filtered_sales
    GROUP BY site_sk
),
returns_by_site_and_reason AS (
    SELECT fs.site_sk,
           r.r_reason_desc,
           COUNT(*) AS reason_cnt,
           SUM(wr.wr_return_amt_inc_tax) AS return_amount
    FROM filtered_sales fs
    JOIN web_returns wr
      ON fs.ws_order_number = wr.wr_order_number
     AND fs.ws_item_sk = wr.wr_item_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY fs.site_sk, r.r_reason_desc
),
total_returns_by_site AS (
    SELECT site_sk,
           SUM(return_amount) AS total_returns
    FROM returns_by_site_and_reason
    GROUP BY site_sk
),
reason_rank AS (
    SELECT site_sk,
           r_reason_desc,
           reason_cnt,
           ROW_NUMBER() OVER (PARTITION BY site_sk ORDER BY reason_cnt DESC) AS rn
    FROM returns_by_site_and_reason
),
final AS (
    SELECT s.site_sk,
           s.total_sales,
           COALESCE(t.total_returns, 0) AS total_returns,
           s.total_sales - COALESCE(t.total_returns, 0) AS net_profit_after_returns,
           rr.r_reason_desc AS top_return_reason,
           rr.reason_cnt AS top_reason_count
    FROM sales_agg s
    LEFT JOIN total_returns_by_site t
      ON s.site_sk = t.site_sk
    LEFT JOIN reason_rank rr
      ON s.site_sk = rr.site_sk
     AND rr.rn = 1
)
SELECT ws.web_name,
       f.total_sales,
       f.total_returns,
       f.net_profit_after_returns,
       f.top_return_reason,
       f.top_reason_count,
       RANK() OVER (ORDER BY f.net_profit_after_returns DESC) AS profit_rank
FROM final f
JOIN web_site ws
  ON f.site_sk = ws.web_site_sk
ORDER BY profit_rank
LIMIT 10
