/*
Goal: Compare recent catalog sales that occurred in 2001 during the morning shift with store closures in the same year. For each qualifying sale we show the sale date, net amount paid (including tax), and the total quantity ordered (computed via a LATERAL sub‑query). Store‑closure rows are included with NULL placeholders for the sales metrics so the two result sets can be UNIONed together. The final combined result is ordered by date and source type and limited to the top 100 rows.
*/
WITH avg_net_paid AS (
    SELECT avg(cs_net_paid_inc_tax) AS avg_val
    FROM catalog_sales
)
SELECT *
FROM (
    SELECT
        d.d_date AS sale_date,
        cs.cs_net_paid_inc_tax AS net_paid,
        l.total_qty AS total_quantity,
        CAST('catalog' AS varchar) AS source_type
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT sum(cs2.cs_quantity) AS total_qty
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = cs.cs_order_number
    ) AS l
    WHERE d.d_year = 2001
      AND t.t_sub_shift = 'morning'
      AND cs.cs_net_paid_inc_tax > (SELECT avg_val FROM avg_net_paid)
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          WHERE hd.hd_demo_sk = cs.cs_bill_hdemo_sk
            AND hd.hd_income_band_sk = 5
      )
    UNION ALL
    SELECT
        d.d_date AS sale_date,
        CAST(null AS decimal(7,2)) AS net_paid,
        CAST(null AS integer) AS total_quantity,
        CAST('store_close' AS varchar) AS source_type
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
) AS combined
ORDER BY sale_date DESC, source_type
LIMIT 100
