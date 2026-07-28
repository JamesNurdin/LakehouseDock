WITH first_part AS (
    SELECT
        i.i_brand AS brand,
        cd.cd_gender AS gender,
        'steel_college' AS segment,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_fee) AS total_fee,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_formulation LIKE '%steel%'
      AND cd.cd_education_status = 'College'
      AND sr.sr_return_quantity > 1
    GROUP BY i.i_brand, cd.cd_gender
),
second_part AS (
    SELECT
        i.i_brand AS brand,
        cd.cd_gender AS gender,
        'wheat_primary' AS segment,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_fee) AS total_fee,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_formulation LIKE '%wheat%'
      AND cd.cd_education_status = 'Primary'
      AND sr.sr_return_quantity >= 2
    GROUP BY i.i_brand, cd.cd_gender
)
SELECT
    brand,
    gender,
    segment,
    total_return_amount,
    total_fee,
    return_count
FROM first_part
UNION ALL
SELECT
    brand,
    gender,
    segment,
    total_return_amount,
    total_fee,
    return_count
FROM second_part
ORDER BY brand, gender, segment
