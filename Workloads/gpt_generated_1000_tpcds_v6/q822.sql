WITH dept_income_agg AS (
    SELECT
        cp.cp_department AS department,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_net_loss) AS catalog_loss,
        SUM(sr.sr_net_loss) AS store_loss,
        COUNT(*) AS total_returns
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        cp.cp_department IS NOT NULL
        AND cr.cr_returned_time_sk IN (22065, 28638, 37877)
        AND cd.cd_gender = 'F'
        AND hd.hd_buy_potential = '1001-5000'
        AND ib.ib_upper_bound >= 5000
        AND td.t_hour BETWEEN 9 AND 17
    GROUP BY
        cp.cp_department,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    department,
    AVG(total_loss) AS avg_total_loss,
    SUM(total_returns) AS sum_total_returns
FROM (
    SELECT
        department,
        (catalog_loss + store_loss) AS total_loss,
        total_returns
    FROM dept_income_agg
) agg
GROUP BY department
HAVING AVG(total_loss) > 0
ORDER BY avg_total_loss DESC
LIMIT 100
