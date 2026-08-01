WITH intersect_cust AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2002
    )
    INTERSECT
    SELECT sr.sr_customer_sk AS cust_sk
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2002
    )
),

sales_agg AS (
    SELECT
        d.d_year AS year,
        'Sales' AS segment,
        cd.cd_gender AS gender,
        SUM(cs.cs_net_paid) AS total_amount,
        cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        d.d_year = 2002
        AND cs.cs_quantity > 5
        AND sm.sm_type = 'AIR'
        AND cd.cd_credit_rating = 'Good'
        AND cs.cs_bill_customer_sk IN (SELECT cust_sk FROM intersect_cust)
    GROUP BY d.d_year, cd.cd_gender, cs.cs_bill_customer_sk
),

returns_agg AS (
    SELECT
        d.d_year AS year,
        'Returns' AS segment,
        cd.cd_gender AS gender,
        SUM(sr.sr_return_amt) AS total_amount,
        sr.sr_customer_sk AS cust_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        d.d_year = 2002
        AND sr.sr_return_quantity > 2
        AND r.r_reason_desc LIKE '%missing%'
        AND cd.cd_marital_status = 'M'
        AND sr.sr_customer_sk IN (SELECT cust_sk FROM intersect_cust)
    GROUP BY d.d_year, cd.cd_gender, sr.sr_customer_sk
),

union_data AS (
    SELECT year, segment, gender, total_amount, cust_sk FROM sales_agg
    UNION DISTINCT
    SELECT year, segment, gender, total_amount, cust_sk FROM returns_agg
),

sampled AS (
    SELECT year, segment, gender, total_amount, cust_sk
    FROM union_data
    TABLESAMPLE BERNOULLI (10)
),

final AS (
    SELECT
        sd.year,
        sd.segment,
        sd.gender,
        sd.total_amount,
        sd.cust_sk,
        (
            SELECT SUM(cs2.cs_net_paid)
            FROM catalog_sales cs2
            WHERE cs2.cs_bill_customer_sk = sd.cust_sk
        ) AS customer_total_sales,
        l.avg_return_for_gender
    FROM sampled sd
    LEFT JOIN LATERAL (
        SELECT AVG(sr2.sr_return_amt) AS avg_return_for_gender
        FROM store_returns sr2
        JOIN customer_demographics cd2 ON sr2.sr_cdemo_sk = cd2.cd_demo_sk
        WHERE cd2.cd_gender = sd.gender
    ) l ON TRUE
    WHERE sd.total_amount > 0
)
SELECT
    year,
    segment,
    gender,
    total_amount,
    customer_total_sales,
    avg_return_for_gender
FROM final
ORDER BY year DESC, segment, total_amount DESC
LIMIT 100
