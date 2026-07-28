WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_returning_customer_sk,
        wr.wr_returning_cdemo_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_returning_addr_sk,
        wr.wr_web_page_sk,
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_fee,
        wr.wr_return_ship_cost,
        wr.wr_refunded_cash,
        wr.wr_reversed_charge,
        wr.wr_account_credit,
        wr.wr_net_loss
    FROM web_returns wr
    WHERE wr.wr_return_amt > 100
),
joined_data AS (
    SELECT
        i.i_category,
        i.i_brand,
        cd.cd_gender,
        ib.ib_upper_bound,
        ib.ib_lower_bound,
        d.d_year,
        d.d_month_seq,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_amt_inc_tax,
        wr.wr_return_ship_cost,
        wr.wr_order_number,
        wp.wp_type
    FROM filtered_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_refunded
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND i.i_brand_id IN (2004002, 8007005)
      AND i.i_formulation LIKE '%steel%'
      AND c_refunded.c_birth_country = 'United States'
      AND ib.ib_lower_bound >= 50000
),
aggregated AS (
    SELECT
        i_category,
        i_brand,
        cd_gender,
        CASE WHEN ib_upper_bound > 100000 THEN 'High Income' ELSE 'Mid/Low Income' END AS income_category,
        COUNT(DISTINCT wr_order_number) AS num_orders,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_amt_inc_tax) AS avg_return_inc_tax,
        MAX(wr_return_ship_cost) AS max_ship_cost,
        (SELECT AVG(i2.i_current_price)
         FROM item i2
         WHERE i2.i_category = jd.i_category) AS avg_category_price
    FROM joined_data jd
    GROUP BY i_category, i_brand, cd_gender, ib_upper_bound
)
SELECT *
FROM aggregated
ORDER BY total_return_amt DESC
LIMIT 100
