WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        i.i_category,
        ca.ca_country
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_month = 7
      AND ss.ss_sold_date_sk BETWEEN 2452000 AND 2453000
),
sales_with_returns AS (
    SELECT
        fs.i_category,
        fs.ca_country,
        fs.ss_customer_sk,
        fs.ss_net_profit,
        fs.ss_ext_discount_amt,
        fs.ss_quantity,
        COALESCE(sr.sr_net_loss, 0) AS return_loss
    FROM filtered_sales fs
    LEFT JOIN store_returns sr
        ON fs.ss_ticket_number = sr.sr_ticket_number
        AND fs.ss_item_sk = sr.sr_item_sk
),
agg AS (
    SELECT
        i_category,
        ca_country,
        SUM(ss_net_profit) AS total_sales_profit,
        SUM(return_loss) AS total_return_loss,
        SUM(ss_net_profit) - SUM(return_loss) AS net_profit_after_returns,
        SUM(ss_ext_discount_amt) AS total_discount_amount,
        AVG(ss_ext_discount_amt) AS avg_discount_amount,
        COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
        SUM(ss_quantity) AS total_units_sold
    FROM sales_with_returns
    GROUP BY i_category, ca_country
    HAVING SUM(ss_net_profit) - SUM(return_loss) > 1000
)
SELECT
    i_category,
    ca_country,
    total_sales_profit,
    total_return_loss,
    net_profit_after_returns,
    total_discount_amount,
    avg_discount_amount,
    distinct_customers,
    total_units_sold,
    RANK() OVER (PARTITION BY ca_country ORDER BY net_profit_after_returns DESC) AS category_rank_by_country
FROM agg
ORDER BY ca_country, category_rank_by_country
LIMIT 100
