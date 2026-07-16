WITH recent_year AS (
    SELECT MAX(d_year) AS yr FROM date_dim
),
sales_union AS (
    SELECT ss_customer_sk AS c_customer_sk, ss_sold_date_sk AS sold_date_sk,
           ss_quantity AS channel_quantity, ss_net_paid AS channel_net_paid
    FROM store_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS c_customer_sk, ws_sold_date_sk AS sold_date_sk,
           ws_quantity AS channel_quantity, ws_net_paid AS channel_net_paid
    FROM web_sales
    UNION ALL
    SELECT cs_bill_customer_sk AS c_customer_sk, cs_sold_date_sk AS sold_date_sk,
           cs_quantity AS channel_quantity, cs_net_paid AS channel_net_paid
    FROM catalog_sales
),
customer_sales AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           ca.ca_state,
           SUM(s.channel_net_paid) AS total_net_paid,
           SUM(s.channel_quantity) AS total_qty
    FROM sales_union s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    CROSS JOIN recent_year ry
    JOIN customer c ON s.c_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year = ry.yr
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_state
),
ranked_customers AS (
    SELECT *,
           RANK() OVER (ORDER BY total_net_paid DESC) AS sales_rank,
           SUM(total_net_paid) OVER () AS grand_total
    FROM customer_sales
),
top_customers AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           ca_state,
           total_net_paid,
           sales_rank,
           total_net_paid / grand_total AS pct_of_total
    FROM ranked_customers
    WHERE sales_rank <= 10
),
category_sales AS (
    SELECT i.i_category,
           d.d_year,
           SUM(cs.cs_ext_sales_price) AS cat_sales,
           SUM(cs.cs_quantity) AS cat_qty
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY ROLLUP(i.i_category, d.d_year)
)
SELECT tc.c_customer_sk,
       tc.c_first_name,
       tc.c_last_name,
       tc.ca_state,
       tc.total_net_paid,
       tc.sales_rank,
       CAST(tc.pct_of_total * 100 AS DECIMAL(5,2)) AS pct_of_total_percent,
       cs.i_category,
       cs.d_year,
       cs.cat_sales,
       cs.cat_qty,
       SUM(cs.cat_sales) OVER (PARTITION BY cs.i_category ORDER BY cs.d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales_by_category
FROM top_customers tc
LEFT JOIN (
    SELECT i_category, d_year, cat_sales, cat_qty
    FROM category_sales
    WHERE i_category IS NOT NULL AND d_year IS NOT NULL
) cs ON TRUE
ORDER BY tc.sales_rank, cs.i_category, cs.d_year
