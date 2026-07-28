WITH cust_demo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        h.hd_income_band_sk,
        h.hd_vehicle_count,
        h.hd_buy_potential
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics h
      ON c.c_current_hdemo_sk = h.hd_demo_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND cd.cd_education_status LIKE '%Degree'
)
SELECT
    cd.c_customer_sk,
    concat(cd.c_first_name, ' ', cd.c_last_name) AS full_name,
    cd.c_email_address,
    cd.c_birth_year,
    cd.cd_gender,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.hd_income_band_sk,
    cd.hd_vehicle_count,
    cd.hd_buy_potential,
    (
        SELECT COUNT(*)
        FROM tpcds.customer c2
        JOIN tpcds.customer_demographics cd2 ON c2.c_current_cdemo_sk = cd2.cd_demo_sk
        JOIN tpcds.household_demographics h2 ON c2.c_current_hdemo_sk = h2.hd_demo_sk
        WHERE h2.hd_income_band_sk = cd.hd_income_band_sk
          AND h2.hd_vehicle_count > 2
    ) AS peers_with_many_vehicles
FROM cust_demo cd
WHERE NOT EXISTS (
    SELECT 1
    FROM (VALUES ('bad@example.com'), ('spam@example.com')) AS blk(domain)
    WHERE lower(regexp_extract(cd.c_email_address, '@(.+)$')) = blk.domain
)
GROUP BY
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    cd.c_birth_year,
    cd.cd_gender,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.hd_income_band_sk,
    cd.hd_vehicle_count,
    cd.hd_buy_potential
HAVING cd.cd_purchase_estimate > 2000
ORDER BY cd.cd_purchase_estimate DESC, cd.hd_vehicle_count DESC
LIMIT 100
