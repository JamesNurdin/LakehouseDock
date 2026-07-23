WITH sales_by_hour AS (
    SELECT
        td.t_hour,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_store_name LIKE '%Store%'
      AND regexp_like(s.s_store_name, '^.{3,}$')
    GROUP BY td.t_hour, s.s_store_name
),
returns_by_hour AS (
    SELECT
        td.t_hour,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*example\\.com.*$')
    GROUP BY td.t_hour
),
combined AS (
    SELECT
        s.t_hour,
        s.s_store_name,
        s.total_net_profit,
        COALESCE(r.total_net_loss, 0) AS total_net_loss,
        s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_profit_after_returns
    FROM sales_by_hour s
    LEFT JOIN returns_by_hour r ON s.t_hour = r.t_hour
    GROUP BY s.t_hour, s.s_store_name, s.total_net_profit, r.total_net_loss
    HAVING s.total_net_profit - COALESCE(r.total_net_loss, 0) > 1000
)
SELECT
    c.t_hour,
    c.s_store_name,
    substr(c.s_store_name, 1, 3) || '-' || CASE WHEN c.t_hour BETWEEN 12 AND 20 THEN 'Peak' ELSE 'Off-Peak' END AS store_period_key,
    c.total_net_profit,
    c.total_net_loss,
    c.net_profit_after_returns,
    CASE
        WHEN c.t_hour BETWEEN 12 AND 20 THEN 'Peak'
        ELSE 'Off-Peak'
    END AS period_category,
    ROW_NUMBER() OVER (
        PARTITION BY CASE WHEN c.t_hour BETWEEN 12 AND 20 THEN 'Peak' ELSE 'Off-Peak' END
        ORDER BY c.net_profit_after_returns DESC
    ) AS rank_in_period,
    SUM(c.net_profit_after_returns) OVER (
        PARTITION BY CASE WHEN c.t_hour BETWEEN 12 AND 20 THEN 'Peak' ELSE 'Off-Peak' END
        ORDER BY c.t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit
FROM combined c
ORDER BY c.net_profit_after_returns DESC
