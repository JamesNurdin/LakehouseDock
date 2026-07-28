/*
Goal: Summarize 1998 catalog sales by state and product category for high‑income customers while excluding orders that were later returned, and combine this with a summary of returns for dissatisfied customers. The query demonstrates:
- joins across all 13 selected tables using only the permitted keys
- three selective predicates (year, income band, state, and return reason)
- aggregation with SUM, COUNT, and window function ROW_NUMBER()
- an anti‑join via NOT EXISTS
- a LEFT OUTER JOIN to store (to force an outer‑join operator)
- a UNION ALL that merges two sub‑selects
*/
WITH sales_data AS (
    SELECT
        cs.cs_order_number               AS order_number,
        d.d_year                         AS year,
        ca.ca_state                      AS state,
        i.i_category                     AS category,
        SUM(cs.cs_ext_sales_price)       AS amount,
        SUM(cs.cs_quantity)              AS cnt,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rn
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN store s             ON s.s_closed_date_sk = d.d_date_sk   -- outer join
    WHERE d.d_year = 1998
      AND ib.ib_upper_bound >= 120000
      AND ca.ca_state IN ('CA', 'NY', 'TX')
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = cs.cs_order_number
      )
    GROUP BY cs.cs_order_number, d.d_year, ca.ca_state, i.i_category
),
returns_data AS (
    SELECT
        wr.wr_order_number               AS order_number,
        d.d_year                         AS year,
        CAST(NULL AS varchar)            AS state,
        CAST(NULL AS varchar)            AS category,
        SUM(wr.wr_return_amt)            AS amount,
        COUNT(*)                         AS cnt,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(wr.wr_return_amt) DESC) AS rn
    FROM web_returns wr
    JOIN date_dim d               ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t               ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r                 ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i                   ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca      ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN web_site ws              ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
      AND r.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY wr.wr_order_number, d.d_year
    HAVING SUM(wr.wr_return_amt) > 100
)
SELECT
    order_number,
    year,
    state,
    category,
    amount,
    cnt,
    rn,
    'sales'   AS source_type
FROM sales_data
UNION ALL
SELECT
    order_number,
    year,
    state,
    category,
    amount,
    cnt,
    rn,
    'returns' AS source_type
FROM returns_data
ORDER BY year, amount DESC
