WITH ss_summary AS (
    SELECT ss_customer_sk,
           SUM(ss_net_paid) AS sum_net_paid,
           COUNT(*) AS cnt_sales
    FROM store_sales
    GROUP BY ss_customer_sk
),
wr_summary AS (
    SELECT wr_returning_customer_sk,
           COUNT(*) AS cnt_returns,
           SUM(wr_return_amt) AS sum_return_amt
    FROM web_returns
    GROUP BY wr_returning_customer_sk
)
SELECT *
FROM (
    SELECT
        cust.c_customer_id,
        cust.c_first_name,
        cust.c_last_name,
        CASE WHEN cust.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Regular' END AS cust_type,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_net_paid,
        ss.ss_ext_sales_price,
        time_sold.t_meal_time,
        ca_store.ca_city AS store_city,
        ca_return.ca_city AS return_city,
        wp.wp_url,
        -- correlated scalar subquery
        (SELECT SUM(wr2.wr_return_amt)
         FROM web_returns wr2
         WHERE wr2.wr_returning_customer_sk = cust.c_customer_sk) AS total_return_amount,
        -- value from unnest
        sales_val,
        -- running sum of net paid per customer
        SUM(ss.ss_net_paid) OVER (
            PARTITION BY cust.c_customer_sk
            ORDER BY ss.ss_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_net_paid,
        -- previous net paid value
        LAG(ss.ss_net_paid) OVER (
            PARTITION BY cust.c_customer_sk
            ORDER BY ss.ss_sold_date_sk
        ) AS lag_net_paid,
        -- ranking per customer by net paid
        ROW_NUMBER() OVER (
            PARTITION BY cust.c_customer_sk
            ORDER BY ss.ss_net_paid DESC
        ) AS rank_per_cust,
        ss_summary.sum_net_paid AS customer_total_net_paid,
        wr_summary.cnt_returns,
        wr_summary.sum_return_amt
    FROM
        customer cust
        LEFT JOIN customer_demographics cd ON cust.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON cust.c_current_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        -- detailed store_sales
        LEFT JOIN store_sales ss ON cust.c_customer_sk = ss.ss_customer_sk
        LEFT JOIN time_dim time_sold ON ss.ss_sold_time_sk = time_sold.t_time_sk
        LEFT JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
        -- web_returns
        LEFT JOIN web_returns wr ON cust.c_customer_sk = wr.wr_returning_customer_sk
        LEFT JOIN time_dim time_return ON wr.wr_returned_time_sk = time_return.t_time_sk
        LEFT JOIN customer_address ca_return ON wr.wr_returning_addr_sk = ca_return.ca_address_sk
        -- full outer join web_page
        FULL OUTER JOIN web_page wp ON wp.wp_customer_sk = cust.c_customer_sk
        LEFT JOIN web_page wp_ref ON wp_ref.wp_web_page_sk = wr.wr_web_page_sk
        -- pre‑aggregated summaries
        LEFT JOIN ss_summary ON cust.c_customer_sk = ss_summary.ss_customer_sk
        LEFT JOIN wr_summary ON cust.c_customer_sk = wr_summary.wr_returning_customer_sk
        -- unnest an array built from two sales metrics
        CROSS JOIN UNNEST(ARRAY[ss.ss_ext_sales_price, ss.ss_ext_discount_amt]) AS t(sales_val)
    WHERE
        ib.ib_lower_bound >= 100000
        AND EXISTS (
            SELECT 1 FROM store_sales ss3
            WHERE ss3.ss_customer_sk = cust.c_customer_sk
              AND ss3.ss_net_paid > 500
        )
) sub
WHERE rank_per_cust <= 2
ORDER BY c_customer_id, rank_per_cust
LIMIT 100
