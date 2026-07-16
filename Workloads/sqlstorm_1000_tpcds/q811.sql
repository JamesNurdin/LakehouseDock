WITH raw_sales AS (
 SELECT cs_sold_date_sk AS sale_date_sk,
        cs_bill_customer_sk AS c_customer_sk,
        cs_ext_sales_price AS sales_amount,
        cs_ext_tax AS sales_tax,
        cs_net_paid AS net_paid,
        cs_net_profit AS net_profit
 FROM catalog_sales
 UNION ALL
 SELECT ss_sold_date_sk,
        ss_customer_sk,
        ss_ext_sales_price,
        ss_ext_tax,
        ss_net_paid,
        ss_net_profit
 FROM store_sales
 UNION ALL
 SELECT ws_sold_date_sk,
        ws_bill_customer_sk,
        ws_ext_sales_price,
        ws_ext_tax,
        ws_net_paid,
        ws_net_profit
 FROM web_sales
), sales_with_holiday AS (
 SELECT s.*,
        CASE WHEN d.d_holiday = 'Y' THEN 1 ELSE 0 END AS is_holiday
 FROM raw_sales s
 LEFT JOIN date_dim d ON s.sale_date_sk = d.d_date_sk
), sales_agg AS (
 SELECT c_customer_sk,
        MIN(sale_date_sk) AS first_sale_date_sk,
        SUM(sales_amount) AS total_sales_amount,
        SUM(sales_tax) AS total_sales_tax,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(CASE WHEN is_holiday = 1 THEN net_paid ELSE 0 END) AS holiday_net_paid,
        COUNT(*) AS sales_count
 FROM sales_with_holiday
 GROUP BY c_customer_sk
), raw_returns AS (
 SELECT cr_returned_date_sk AS return_date_sk,
        cr_returning_customer_sk AS c_customer_sk,
        cr_return_amount AS return_amount,
        cr_return_tax AS return_tax,
        cr_return_amt_inc_tax AS return_amt_inc_tax,
        cr_net_loss AS net_loss
 FROM catalog_returns
 UNION ALL
 SELECT sr_returned_date_sk,
        sr_customer_sk,
        sr_return_amt,
        sr_return_tax,
        sr_return_amt_inc_tax,
        sr_net_loss
 FROM store_returns
 UNION ALL
 SELECT wr_returned_date_sk,
        wr_returning_customer_sk,
        wr_return_amt,
        wr_return_tax,
        wr_return_amt_inc_tax,
        wr_net_loss
 FROM web_returns
), returns_agg AS (
 SELECT c_customer_sk,
        MIN(return_date_sk) AS first_return_date_sk,
        SUM(return_amount) AS total_return_amount,
        SUM(return_tax) AS total_return_tax,
        SUM(net_loss) AS total_net_loss,
        COUNT(*) AS returns_count
 FROM raw_returns
 GROUP BY c_customer_sk
), customer_info AS (
 SELECT c.c_customer_sk,
        CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
        CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Normal' END AS cust_type,
        cd.cd_gender,
        cd.cd_education_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE WHEN c.c_birth_year IS NULL THEN NULL ELSE year(DATE '2024-10-01') - c.c_birth_year END AS age
 FROM customer c
 LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
 LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
 LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), combined AS (
 SELECT COALESCE(s.c_customer_sk, r.c_customer_sk) AS c_customer_sk,
        COALESCE(ci.full_name, 'Unknown') AS full_name,
        COALESCE(ci.cust_type, 'Unknown') AS cust_type,
        ci.age,
        COALESCE(ci.cd_gender, 'Unknown') AS gender,
        COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(s.total_sales_tax, 0) AS total_sales_tax,
        COALESCE(s.total_net_paid, 0) AS total_net_paid,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_return_tax, 0) AS total_return_tax,
        COALESCE(r.total_net_loss, 0) AS total_net_loss,
        COALESCE(s.sales_count, 0) + COALESCE(r.returns_count, 0) AS total_transactions,
        s.first_sale_date_sk,
        r.first_return_date_sk,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(ci.cust_type, 'Unknown') ORDER BY COALESCE(s.total_net_paid, 0) DESC) AS rank_in_type
 FROM sales_agg s
 FULL OUTER JOIN returns_agg r ON s.c_customer_sk = r.c_customer_sk
 LEFT JOIN customer_info ci ON COALESCE(s.c_customer_sk, r.c_customer_sk) = ci.c_customer_sk
), final AS (
 SELECT c.c_customer_sk,
        c.full_name,
        c.cust_type,
        c.age,
        c.gender,
        c.total_sales_amount,
        c.total_sales_tax,
        c.total_net_paid,
        c.total_net_profit,
        c.total_return_amount,
        c.total_return_tax,
        c.total_net_loss,
        c.total_transactions,
        c.rank_in_type,
        CASE WHEN c.total_net_paid - c.total_net_loss > 0 THEN 'Profit' ELSE 'Loss' END AS overall_status,
        CONCAT('Customer ', CAST(c.c_customer_sk AS varchar), ': ', c.full_name) AS description,
        (SELECT MIN(d.d_date) FROM date_dim d WHERE d.d_date_sk = c.first_sale_date_sk) AS first_sale_date,
        (SELECT MIN(d.d_date) FROM date_dim d WHERE d.d_date_sk = c.first_return_date_sk) AS first_return_date,
        round((c.total_net_paid + c.total_net_profit) / nullif(c.total_transactions, 0), 2) AS loyalty_score
 FROM combined c
 WHERE c.total_net_paid > 0
   AND (c.rank_in_type <= 10 OR (c.age IS NOT NULL AND c.age BETWEEN 30 AND 40))
   AND (c.total_net_paid / nullif(c.total_transactions, 0)) > 1000
)
SELECT *
FROM final
ORDER BY total_net_paid DESC
LIMIT 50
