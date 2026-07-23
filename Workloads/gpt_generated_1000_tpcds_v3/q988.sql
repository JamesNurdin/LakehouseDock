WITH store_agg AS (
    SELECT ca.ca_state AS state,
           sum(ss.ss_net_paid) AS total_amount,
           'store' AS sales_channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND hd.hd_income_band_sk > 10
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          JOIN date_dim d2 ON cs2.cs_ship_date_sk = d2.d_date_sk
          WHERE d2.d_year = 2001
            AND cs2.cs_ship_addr_sk = ca.ca_address_sk
      )
    GROUP BY ca.ca_state
    HAVING sum(ss.ss_net_paid) > (
        SELECT avg(ss2.ss_net_paid)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    )
),
catalog_agg AS (
    SELECT ca.ca_state AS state,
           sum(cs.cs_net_paid_inc_tax) AS total_amount,
           'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND hd.hd_income_band_sk > 10
    GROUP BY ca.ca_state
    HAVING sum(cs.cs_net_paid_inc_tax) > (
        SELECT avg(cs2.cs_net_paid_inc_tax)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    )
)
SELECT state, total_amount, sales_channel
FROM store_agg
UNION ALL
SELECT state, total_amount, sales_channel
FROM catalog_agg
ORDER BY total_amount DESC, state
LIMIT 100
