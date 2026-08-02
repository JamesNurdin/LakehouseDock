WITH joined_facts AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_return_time_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss AS store_net_loss,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_net_loss AS catalog_net_loss,
        c.c_customer_id,
        c.c_birth_country,
        ca.ca_state,
        ca.ca_country,
        ca.ca_gmt_offset,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        t.t_hour,
        t.t_meal_time
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_reason_sk = r.r_reason_sk
    WHERE
        cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_credit_rating = 'Good'
        AND ca.ca_country = 'United States'
        AND ca.ca_gmt_offset = -7.00
        AND c.c_birth_country = 'KOREA'
        AND ib.ib_lower_bound >= 50000
        AND ib.ib_upper_bound <= (SELECT AVG(ib2.ib_upper_bound) FROM income_band ib2)
        AND t.t_hour BETWEEN 9 AND 17
        AND r.r_reason_desc LIKE '%Damaged%'
        AND EXISTS (
            SELECT 1 FROM reason r2
            WHERE r2.r_reason_desc = r.r_reason_desc
              AND r2.r_reason_sk <> r.r_reason_sk
        )
),
state_agg AS (
    SELECT
        ca_state,
        SUM(store_net_loss) AS total_store_loss,
        SUM(catalog_net_loss) AS total_catalog_loss,
        COUNT(DISTINCT sr_customer_sk) AS distinct_customers,
        AVG(store_net_loss) AS avg_store_loss,
        COUNT(*) AS total_returns
    FROM joined_facts
    GROUP BY ca_state
    HAVING COUNT(*) > 10
)
SELECT
    ca_state,
    total_store_loss,
    total_catalog_loss,
    distinct_customers,
    avg_store_loss,
    CASE WHEN total_catalog_loss <> 0 THEN total_store_loss / total_catalog_loss ELSE NULL END AS loss_ratio,
    ROW_NUMBER() OVER (ORDER BY total_store_loss DESC) AS loss_rank
FROM state_agg
WHERE ca_state IN (
    SELECT ca_state FROM state_agg
    EXCEPT
    SELECT ca_state FROM (
        SELECT ca_state
        FROM joined_facts
        WHERE r_reason_desc = 'Other Reason'
    ) AS exclude_states
)
ORDER BY total_store_loss DESC
LIMIT 100
