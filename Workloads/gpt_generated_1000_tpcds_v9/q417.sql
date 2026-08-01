WITH base_sales AS (
    SELECT
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d.d_year,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2002
      AND cd.cd_gender = 'M'
      AND cd.cd_marital_status = 'M'
      AND cd.cd_dep_count >= 2
      AND ib.ib_upper_bound <= 80000
      AND ca.ca_state = 'CA'
      AND cs.cs_quantity > 5
      AND cs.cs_net_profit > 0
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    d_year,
    ca_state,
    cd_gender,
    CAST(NULL AS varchar) AS cd_marital_status,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_net_profit) AS avg_net_profit,
    COUNT(*) AS order_count
FROM base_sales
GROUP BY ROLLUP (d_year, ca_state, cd_gender)

UNION DISTINCT

SELECT
    CAST(NULL AS integer) AS d_year,
    CAST(NULL AS varchar) AS ca_state,
    cd_gender,
    cd_marital_status,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_net_profit) AS avg_net_profit,
    COUNT(*) AS order_count
FROM base_sales
GROUP BY CUBE (cd_gender, cd_marital_status)

ORDER BY d_year, ca_state, cd_gender, cd_marital_status
LIMIT 100
