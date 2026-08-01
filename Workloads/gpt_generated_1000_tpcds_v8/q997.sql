WITH inv_sample AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of inventory rows
),
joined AS (
    SELECT
        d1.d_year,
        hd_ref.hd_buy_potential,
        cr.cr_return_amount,
        wr.wr_return_amt,
        cr.cr_order_number,
        wr.wr_order_number,
        p.p_promo_id,
        pc.channel_detail,
        ib.ib_upper_bound
    FROM catalog_returns cr
    JOIN date_dim d1
        ON cr.cr_returned_date_sk = d1.d_date_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN inv_sample inv
        ON inv.inv_date_sk = d1.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d1.d_date_sk
    JOIN date_dim d2
        ON p.p_end_date_sk = d2.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d1.d_date_sk
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN LATERAL (
        SELECT TRIM(value) AS channel_detail
        FROM UNNEST(split(p.p_channel_details, ',')) AS t(value)
    ) pc ON true
    WHERE cr.cr_return_amount > 0
      AND cr.cr_order_number IN (
          SELECT cr_order_number FROM catalog_returns WHERE cr_return_amount > 50
          INTERSECT
          SELECT wr_order_number FROM web_returns WHERE wr_return_amt > 50
      )
)
SELECT
    d_year,
    hd_buy_potential,
    COUNT(DISTINCT cr_order_number)      AS catalog_order_cnt,
    COUNT(DISTINCT wr_order_number)      AS web_order_cnt,
    SUM(cr_return_amount)                AS total_catalog_return,
    SUM(wr_return_amt)                   AS total_web_return,
    AVG(cr_return_amount)                AS avg_catalog_return,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper,
    COUNT(DISTINCT channel_detail)       AS distinct_promo_channels
FROM joined
GROUP BY ROLLUP (d_year, hd_buy_potential)
ORDER BY d_year DESC NULLS LAST, hd_buy_potential
LIMIT 100
