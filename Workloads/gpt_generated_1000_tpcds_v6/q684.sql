WITH sales_agg AS (
    SELECT
        ca.ca_state,
        i.i_category,
        cd.cd_gender,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(CASE WHEN cd.cd_credit_rating = 'Good' THEN 1 ELSE 0 END) AS good_credit_cnt,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_location_type IN ('apartment', 'single family')
      AND cd.cd_purchase_estimate >= 3000
      AND cd.cd_credit_rating IN ('Good', 'High Risk')
      AND i.i_units = 'Box'
      AND i.i_current_price BETWEEN 10 AND 100
      AND i.i_manufact LIKE '%cally%'
    GROUP BY ca.ca_state, i.i_category, cd.cd_gender
),
final_stats AS (
    SELECT
        ca_state,
        AVG(total_sales) AS avg_state_sales,
        SUM(good_credit_cnt) AS total_good_credit,
        MAX(total_sales) AS max_state_sales
    FROM sales_agg
    GROUP BY ca_state
    HAVING AVG(total_sales) > 1000
)
SELECT
    ca_state,
    avg_state_sales,
    total_good_credit,
    max_state_sales,
    CASE
        WHEN avg_state_sales > 5000 THEN 'High'
        WHEN avg_state_sales > 2000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_grade
FROM final_stats
ORDER BY avg_state_sales DESC
LIMIT 100
