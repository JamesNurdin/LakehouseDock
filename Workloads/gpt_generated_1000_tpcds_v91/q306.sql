WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),
distinct_demo AS (
    SELECT DISTINCT
        cd_demo_sk,
        cd_gender,
        cd_credit_rating,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
    WHERE cd_credit_rating IN ('Low Risk', 'Good')
      AND cd_dep_employed_count >= 2
)
SELECT
    cd.cd_gender,
    cd.cd_credit_rating,
    ca.ca_state,
    d.d_year,
    hd.hd_buy_potential,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MAX(cr.cr_return_amount) AS max_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss
FROM sampled_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN distinct_demo cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE d.d_dom = 13
  AND d.d_same_day_lq >= 2414940
  AND cr.cr_return_amount > 100
  AND cr.cr_return_quantity BETWEEN 1 AND 5
  AND ca.ca_country = 'United States'
  AND hd.hd_vehicle_count > 1
GROUP BY
    cd.cd_gender,
    cd.cd_credit_rating,
    ca.ca_state,
    d.d_year,
    hd.hd_buy_potential
ORDER BY total_return_amount DESC
LIMIT 100
