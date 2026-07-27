WITH per_store_year AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        SUM(CASE WHEN sr.sr_return_amt > 500 THEN 1 ELSE 0 END) AS high_return_cnt
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND t.t_am_pm = 'PM'
        AND sr.sr_reversed_charge > 10
        AND i.inv_quantity_on_hand < 500
        AND s.s_country = 'United States'
        AND cp.cp_type = 'PROMO'
    GROUP BY
        s.s_store_id,
        d.d_year
)
SELECT
    psy.d_year,
    AVG(psy.total_return_amt) AS avg_store_return_amt,
    SUM(psy.return_cnt) AS total_returns,
    (SELECT MAX(cp_inner.cp_catalog_page_number)
     FROM catalog_page cp_inner
     WHERE cp_inner.cp_type = 'PROMO') AS max_promo_page_number
FROM per_store_year psy
WHERE psy.high_return_cnt >= 1
GROUP BY psy.d_year
HAVING AVG(psy.total_return_amt) > 1000
ORDER BY psy.d_year
