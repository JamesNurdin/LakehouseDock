WITH agg_fact AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        d.d_date_sk AS date_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns,
        (
            SELECT avg(inner_sr.sr_return_amt)
            FROM store_returns inner_sr
            WHERE inner_sr.sr_store_sk = sr.sr_store_sk
        ) AS avg_store_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk >= 8
      AND sr.sr_store_credit > 100
      AND sr.sr_return_quantity > 0
    GROUP BY GROUPING SETS (
        (sr.sr_store_sk, d.d_year, d.d_date_sk),
        (sr.sr_store_sk, d.d_date_sk),
        (d.d_year, d.d_date_sk)
    )
)
SELECT
    ag.sr_store_sk,
    ag.d_year,
    ag.total_return_amt,
    ag.total_net_loss,
    ag.cnt_returns,
    ag.avg_store_return_amt,
    cp.cp_department,
    cr.cr_return_amount,
    wr.wr_return_amt,
    ws.web_name,
    promo_lat.max_discount_active
FROM agg_fact ag
LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = ag.date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   AND cr.cr_returned_date_sk = ag.date_sk
FULL OUTER JOIN web_returns wr
    ON wr.wr_returned_date_sk = ag.date_sk
RIGHT OUTER JOIN web_site ws
    ON ws.web_open_date_sk = ag.date_sk
LEFT JOIN LATERAL (
    SELECT max(p.p_discount_active) AS max_discount_active
    FROM promotion p
    WHERE p.p_start_date_sk = ag.date_sk
) promo_lat ON true
LIMIT 100
