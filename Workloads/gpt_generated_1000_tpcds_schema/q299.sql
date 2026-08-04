-- Goal: Rank catalog and store return performance by year while combining distinct result sets and removing negative net loss rows.
WITH base AS (
    SELECT
        d.d_year AS year,
        cd.cd_gender AS gender,
        sm.sm_code AS ship_code,
        w.web_state AS state,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        sr.sr_return_amt AS store_return_amount,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cr.cr_net_loss DESC) AS rn
    FROM
        store s
        FULL OUTER JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
        INNER JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        INNER JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        INNER JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        INNER JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        INNER JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2001                -- filter 1
        AND t.t_hour = 14                              -- filter 2
        AND cd.cd_credit_rating = 'Good'              -- filter 3
        AND sm.sm_code = 'AIR'                         -- filter 4
        AND w.web_state = 'CA'                         -- filter 5
)
SELECT year, gender, ship_code, state, return_amount, net_loss, store_return_amount, rn
FROM base
UNION DISTINCT
SELECT year, gender, ship_code, state, return_amount, net_loss, store_return_amount, rn
FROM base
WHERE ship_code = 'SEA' AND state = 'NY'
EXCEPT
SELECT year, gender, ship_code, state, return_amount, net_loss, store_return_amount, rn
FROM base
WHERE net_loss < 0
ORDER BY year DESC, rn ASC
LIMIT 100
