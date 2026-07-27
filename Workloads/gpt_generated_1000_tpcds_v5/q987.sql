WITH holiday_returns AS (
    SELECT
        ws.web_county,
        dd.d_year,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = dd.d_date_sk
    WHERE dd.d_holiday = 'Y'
      AND wr.wr_net_loss > (SELECT AVG(wr2.wr_net_loss) FROM web_returns wr2)
    GROUP BY ws.web_county, dd.d_year
),
nonholiday_recent AS (
    SELECT
        ws.web_county,
        dd.d_year,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(wr.wr_net_loss) > 500 THEN 'Medium' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN web_site ws ON ws.web_close_date_sk = dd.d_date_sk
    WHERE dd.d_holiday = 'N'
      AND dd.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY ws.web_county, dd.d_year
)
SELECT *
FROM holiday_returns
UNION ALL
SELECT *
FROM nonholiday_recent
ORDER BY web_county, d_year DESC, total_net_loss DESC
