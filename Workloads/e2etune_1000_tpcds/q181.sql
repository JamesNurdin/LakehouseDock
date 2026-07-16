WITH category_profit AS (
    SELECT
        i.i_category,
        cd.cd_gender,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND cd.cd_gender = 'F'
      AND ss.ss_sold_date_sk BETWEEN 2459200 AND 2459600
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY i.i_category, cd.cd_gender
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    i_category,
    cd_gender,
    total_net_profit,
    total_discount_amount,
    avg_purchase_estimate,
    distinct_customers,
    RANK() OVER (PARTITION BY cd_gender ORDER BY total_net_profit DESC) AS profit_rank
FROM category_profit
ORDER BY total_net_profit DESC
LIMIT 10
