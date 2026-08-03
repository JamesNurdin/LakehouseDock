WITH sampled_sales AS (
    SELECT ss.*
    FROM store_sales ss TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        s.s_store_name,
        d.d_year,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cd.cd_gender,
        cd.cd_education_status,
        sr.sr_fee,
        sr.sr_return_quantity,
        inv.inv_quantity_on_hand,
        t.t_hour
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_store_sk = sr.sr_store_sk
    LEFT JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
      AND t.t_hour BETWEEN 9 AND 17
),
agg_data AS (
    SELECT
        s_store_name,
        d_year,
        SUM(ss_net_paid) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS sales_transactions,
        CASE
            WHEN SUM(ss_net_profit) > 100000 THEN 'High'
            WHEN SUM(ss_net_profit) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM joined_data
    GROUP BY GROUPING SETS (
        (s_store_name, d_year),
        (s_store_name),
        (d_year)
    )
    HAVING SUM(ss_net_paid) > 1000
)
SELECT
    s_store_name,
    d_year,
    total_sales,
    total_profit,
    sales_transactions,
    profit_category,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS sales_rank
FROM agg_data
ORDER BY profit_category DESC, total_sales DESC
LIMIT 100
