SELECT
    cd.cd_marital_status,
    cd.cd_education_status,
    hd.hd_buy_potential,
    i.i_brand,
    COUNT(*) AS num_records,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_est,
    AVG(i.i_current_price) AS avg_item_price,
    SUM(i.i_current_price * cd.cd_purchase_estimate) AS weighted_sales_estimate
FROM
    customer_demographics cd
    JOIN household_demographics hd
        ON cd.cd_dep_count = hd.hd_dep_count
    JOIN item i
        ON hd.hd_income_band_sk = i.i_manufact_id
WHERE
    cd.cd_credit_rating IN ('Good', 'Low Risk')
    AND cd.cd_education_status IN ('College', '4 yr Degree')
    AND i.i_category IN ('Electronics', 'Clothing', 'Furniture')
GROUP BY
    cd.cd_marital_status,
    cd.cd_education_status,
    hd.hd_buy_potential,
    i.i_brand
HAVING
    COUNT(*) > 5
ORDER BY
    avg_purchase_est DESC,
    avg_item_price ASC
LIMIT 100
