/*
  Goal: Compute total net loss of store returns for the year 2002 broken down by customer gender, income band, and website. 
  The query joins all eight selected tables using only the permitted join keys, applies three filter predicates, adds a correlated EXISTS subquery, aggregates with ROLLUP to produce subtotals, uses a scalar correlated subquery to show the yearly net‑loss total, and ranks websites within each year by their net‑loss.
*/
WITH joined_data AS (
    SELECT
        d.d_year,
        cd.cd_gender,
        ib.ib_income_band_sk,
        ws.web_name,
        sr.sr_net_loss,
        sr.sr_customer_sk,
        d.d_date_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2002                                         -- filter 1
      AND ib.ib_upper_bound >= 100000                            -- filter 2
      AND ws.web_gmt_offset = -5.00                               -- filter 3
      AND EXISTS (
            SELECT 1
            FROM inventory i2
            WHERE i2.inv_date_sk = d.d_date_sk
              AND i2.inv_quantity_on_hand > 0
        )
),
agg AS (
    SELECT
        d_year,
        cd_gender,
        ib_income_band_sk,
        web_name,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM joined_data
    GROUP BY ROLLUP (d_year, cd_gender, ib_income_band_sk, web_name)
)
SELECT
    a.d_year,
    a.cd_gender,
    a.ib_income_band_sk,
    a.web_name,
    a.total_net_loss,
    a.returns_cnt,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_loss DESC) AS rank_in_year,
    (
        SELECT SUM(sr2.sr_net_loss)
        FROM store_returns sr2
        JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = a.d_year
    ) AS total_net_loss_year
FROM agg a
WHERE a.total_net_loss IS NOT NULL
ORDER BY a.d_year ASC NULLS LAST,
         rank_in_year ASC NULLS LAST,
         a.web_name
