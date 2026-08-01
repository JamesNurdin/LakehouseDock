/*
Goal: Compare yearly total catalog sales for TV‑inactive promotions against yearly total store return amounts, using a scalar subquery to filter sales above the overall maximum sales price. The query combines the two result sets with UNION ALL, assigns a global ROW_NUMBER, orders by amount descending, and limits to the top 100 rows.
*/
WITH max_price AS (
    SELECT max(cs_ext_sales_price) AS max_val
    FROM catalog_sales
),
combined AS (
    -- Catalog sales for promotions where TV channel is not used and sales price exceeds the overall max price
    SELECT
        d.d_year AS year,
        sum(cs.cs_ext_sales_price) AS amount,
        'sales' AS src
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'N'
      AND cs.cs_ext_sales_price > (SELECT max_val FROM max_price)
    GROUP BY d.d_year

    UNION ALL

    -- Store returns for the fiscal year 2000
    SELECT
        d.d_year AS year,
        sum(sr.sr_return_amt) AS amount,
        'returns' AS src
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year
)
SELECT
    row_number() OVER (ORDER BY c.amount DESC) AS row_num,
    c.year,
    c.amount,
    c.src
FROM combined c
ORDER BY c.amount DESC
LIMIT 100
