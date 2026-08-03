WITH joined_data AS (
    SELECT
        d.d_year,
        w.w_warehouse_name,
        ib.ib_upper_bound,
        CASE WHEN ib.ib_upper_bound > 150000 THEN 'High' ELSE 'Low' END AS income_category,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_item_sk
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND cr.cr_return_amount > (
            SELECT avg(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_returned_date_sk BETWEEN 1000 AND 2000
        )
      AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_item_sk = cr.cr_item_sk
              AND p2.p_discount_active = 'Y'
        )
)
SELECT
    jd.d_year,
    jd.w_warehouse_name,
    jd.income_category,
    SUM(jd.cr_return_amount) AS total_return_amount,
    SUM(jd.cr_return_quantity) AS total_return_quantity,
    CASE
        WHEN SUM(jd.cr_return_amount) > (
            SELECT max(ib2.ib_upper_bound)
            FROM income_band ib2
            WHERE ib2.ib_lower_bound > 60000
        ) THEN 'Very High'
        ELSE 'Normal'
    END AS amount_category
FROM joined_data jd
GROUP BY jd.d_year, jd.w_warehouse_name, jd.income_category
HAVING SUM(jd.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
