WITH agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        w.w_state,
        COUNT(*) AS cnt_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd.cd_education_status = 'College' THEN 1 ELSE 0 END) AS college_educated_count,
        approx_percentile(cd.cd_purchase_estimate, 0.5) AS median_purchase_estimate
    FROM
        customer_demographics cd
        CROSS JOIN household_demographics hd
        CROSS JOIN warehouse w
    WHERE
        cd.cd_credit_rating IN ('Good', 'Low Risk')
        AND cd.cd_gender = 'F'
        AND hd.hd_buy_potential = 'High'
        AND w.w_country = 'United States'
    GROUP BY
        cd.cd_gender,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        w.w_state
    HAVING
        COUNT(*) >= 20
)
SELECT
    cd_gender,
    cd_credit_rating,
    hd_buy_potential,
    w_state,
    cnt_customers,
    avg_purchase_estimate,
    college_educated_count,
    median_purchase_estimate,
    RANK() OVER (ORDER BY avg_purchase_estimate DESC) AS purchase_estimate_rank
FROM agg
ORDER BY avg_purchase_estimate DESC
LIMIT 50
