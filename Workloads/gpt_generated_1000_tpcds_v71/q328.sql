WITH return_enriched AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        sr.sr_item_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        d_ret.d_year,
        i.i_brand,
        i.i_category,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        s.s_store_name
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk <= sr.sr_returned_date_sk
        AND p.p_end_date_sk >= sr.sr_returned_date_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = sr.sr_item_sk
          AND p2.p_channel_catalog = 'N'
    )
)
SELECT
    s2.s_store_name,
    rd.d_year,
    SUM(rd.sr_return_amt) AS total_return_amount,
    COUNT(DISTINCT rd.sr_returned_date_sk) AS distinct_return_days,
    AVG(rd.sr_return_quantity) AS avg_return_quantity,
    (
        SELECT MAX(ib_max.ib_upper_bound)
        FROM income_band ib_max
    ) AS max_income_band_upper
FROM return_enriched rd
JOIN store s2
    ON rd.sr_store_sk = s2.s_store_sk
JOIN date_dim d_closed
    ON s2.s_closed_date_sk = d_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
GROUP BY s2.s_store_name, rd.d_year
ORDER BY total_return_amount DESC
LIMIT 100
