WITH
catalog_agg AS (
    SELECT
        d.d_year,
        hd.hd_buy_potential,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_cnt,
        MAX(regexp_extract(t.t_time_id, 'A+(.*)', 1)) AS time_suffix,
        CASE WHEN SUM(cr.cr_net_loss) > 100 THEN 'High' ELSE 'Low' END AS catalog_loss_category
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd
      ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_day_name LIKE 'S%'
      AND regexp_like(t.t_time_id, '^A{4,}.*$')
    GROUP BY d.d_year, hd.hd_buy_potential
),
web_agg AS (
    SELECT
        d.d_year,
        hd.hd_buy_potential,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_cnt,
        MAX(regexp_extract(t.t_time_id, 'A+(.*)', 1)) AS time_suffix,
        CASE WHEN SUM(wr.wr_net_loss) > 100 THEN 'High' ELSE 'Low' END AS web_loss_category
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd
      ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_day_name LIKE 'S%'
      AND regexp_like(t.t_time_id, '^A{4,}.*$')
    GROUP BY d.d_year, hd.hd_buy_potential
)
SELECT
    COALESCE(c.d_year, w.d_year) AS year,
    COALESCE(c.hd_buy_potential, w.hd_buy_potential) AS buy_potential,
    c.catalog_net_loss,
    w.web_net_loss,
    (c.catalog_net_loss + w.web_net_loss) AS total_net_loss,
    CASE
        WHEN (c.catalog_net_loss + w.web_net_loss) > 200 THEN 'Very High'
        WHEN (c.catalog_net_loss + w.web_net_loss) > 100 THEN 'High'
        ELSE 'Medium'
    END AS total_loss_category,
    COALESCE(c.time_suffix, w.time_suffix) AS sample_time_suffix
FROM catalog_agg c
FULL OUTER JOIN web_agg w
    ON c.d_year = w.d_year
   AND c.hd_buy_potential = w.hd_buy_potential
ORDER BY total_net_loss DESC
LIMIT 100
