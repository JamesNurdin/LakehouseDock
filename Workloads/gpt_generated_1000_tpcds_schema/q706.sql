WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
agg_sales AS (
    SELECT
        c.c_customer_id,
        ca.ca_state,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'High' ELSE 'Medium' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM sampled_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ca.ca_country = 'United States'
      AND hd.hd_vehicle_count > 0
      AND cd.cd_credit_rating = 'Good'
    GROUP BY GROUPING SETS (
        (c.c_customer_id, ca.ca_state, hd.hd_income_band_sk, ib.ib_lower_bound),
        (c.c_customer_id, ca.ca_state),
        ()
    )
),
agg_returns AS (
    SELECT
        c.c_customer_id,
        ca.ca_state,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(sr.sr_return_amt) > 5000 THEN 'High' ELSE 'Low' END AS return_category,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(sr.sr_return_amt) DESC) AS return_rank
    FROM store_returns sr
    JOIN sampled_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE ca.ca_country = 'United States'
      AND hd.hd_vehicle_count > 0
      AND cd.cd_credit_rating = 'Good'
    GROUP BY GROUPING SETS (
        (c.c_customer_id, ca.ca_state, hd.hd_income_band_sk, ib.ib_lower_bound),
        (c.c_customer_id, ca.ca_state),
        ()
    )
),
combined AS (
    SELECT
        c_customer_id,
        ca_state,
        hd_income_band_sk,
        ib_lower_bound,
        total_sales,
        sales_cnt,
        sales_category,
        CAST(NULL AS decimal(7,2)) AS total_returns,
        CAST(NULL AS integer) AS return_cnt,
        CAST(NULL AS varchar) AS return_category,
        sales_rank AS rank_val
    FROM agg_sales
    UNION
    SELECT
        c_customer_id,
        ca_state,
        hd_income_band_sk,
        ib_lower_bound,
        CAST(NULL AS decimal(7,2)) AS total_sales,
        CAST(NULL AS integer) AS sales_cnt,
        CAST(NULL AS varchar) AS sales_category,
        total_returns,
        return_cnt,
        return_category,
        return_rank AS rank_val
    FROM agg_returns
)
SELECT
    c_customer_id,
    ca_state,
    hd_income_band_sk,
    ib_lower_bound,
    total_sales,
    sales_cnt,
    sales_category,
    total_returns,
    return_cnt,
    return_category,
    rank_val
FROM combined
ORDER BY rank_val
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
