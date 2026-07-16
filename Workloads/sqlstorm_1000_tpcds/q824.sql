WITH
store_sales_yr AS (
    SELECT
        ss_customer_sk AS cust_sk,
        d.d_year AS year,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        ss_quantity AS qty,
        ss_promo_sk AS promo_sk,
        ss_sold_date_sk AS sold_date_sk
    FROM store_sales ss
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
web_sales_yr AS (
    SELECT
        ws_bill_customer_sk AS cust_sk,
        d.d_year AS year,
        ws_net_paid AS net_paid,
        ws_net_profit AS net_profit,
        ws_quantity AS qty,
        ws_promo_sk AS promo_sk,
        ws_sold_date_sk AS sold_date_sk
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
catalog_sales_yr AS (
    SELECT
        cs_bill_customer_sk AS cust_sk,
        d.d_year AS year,
        cs_net_paid AS net_paid,
        cs_net_profit AS net_profit,
        cs_quantity AS qty,
        cs_promo_sk AS promo_sk,
        cs_sold_date_sk AS sold_date_sk
    FROM catalog_sales cs
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
all_sales AS (
    SELECT * FROM store_sales_yr
    UNION ALL
    SELECT * FROM web_sales_yr
    UNION ALL
    SELECT * FROM catalog_sales_yr
),
customer_annual_sales AS (
    SELECT
        cust_sk,
        year,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(qty) AS total_quantity,
        COUNT(*) AS sales_transactions,
        MAX(promo_sk) AS max_promo_sk
    FROM all_sales
    GROUP BY cust_sk, year
),
store_ret_yr AS (
    SELECT
        sr_customer_sk AS cust_sk,
        d.d_year AS year,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_return_loss
    FROM store_returns sr
    LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_customer_sk, d.d_year
),
web_ret_yr AS (
    SELECT
        wr_refunded_customer_sk AS cust_sk,
        d.d_year AS year,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_return_loss
    FROM web_returns wr
    LEFT JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY wr.wr_refunded_customer_sk, d.d_year
),
all_returns AS (
    SELECT * FROM store_ret_yr
    UNION ALL
    SELECT * FROM web_ret_yr
),
customer_annual_returns AS (
    SELECT
        cust_sk,
        year,
        SUM(total_return_amt) AS total_return_amt,
        SUM(total_return_loss) AS total_return_loss
    FROM all_returns
    GROUP BY cust_sk, year
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
promo_details AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS is_active
    FROM promotion p
),
final AS (
    SELECT
        ci.c_customer_sk,
        ci.full_name,
        cas.year AS sales_year,
        COALESCE(cas.total_net_paid,0) AS total_net_paid,
        COALESCE(cas.total_net_profit,0) AS total_net_profit,
        COALESCE(cas.total_quantity,0) AS total_quantity,
        COALESCE(cas.sales_transactions,0) AS sales_transactions,
        COALESCE(car.total_return_amt,0) AS total_return_amt,
        COALESCE(car.total_return_loss,0) AS total_return_loss,
        COALESCE(cas.total_net_paid,0) - COALESCE(car.total_return_amt,0) AS net_paid_after_returns,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ib_lower_bound,
        ci.ib_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY cas.year ORDER BY COALESCE(cas.total_net_paid,0) DESC) AS rank_by_net_paid,
        CASE
            WHEN COALESCE(cas.total_net_paid,0) > 200000 THEN 'Platinum'
            WHEN COALESCE(cas.total_net_paid,0) BETWEEN 100001 AND 200000 THEN 'Gold'
            WHEN COALESCE(cas.total_net_paid,0) BETWEEN 50001 AND 100000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier,
        pd.p_promo_name,
        pd.is_active
    FROM customer_info ci
    LEFT JOIN customer_annual_sales cas ON ci.c_customer_sk = cas.cust_sk AND cas.year = 2001
    LEFT JOIN customer_annual_returns car ON ci.c_customer_sk = car.cust_sk AND car.year = 2001
    LEFT JOIN promo_details pd ON cas.max_promo_sk = pd.p_promo_sk
    WHERE (ci.cd_gender = 'F' OR ci.cd_gender IS NULL)
      AND (ci.ib_upper_bound IS NULL OR ci.ib_upper_bound >= 50000)
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs
          JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
          WHERE cs.cs_bill_customer_sk = ci.c_customer_sk
            AND cp.cp_type = 'Technology'
            AND cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
      )
)
SELECT *
FROM final
WHERE rank_by_net_paid <= 10
ORDER BY sales_year, rank_by_net_paid
