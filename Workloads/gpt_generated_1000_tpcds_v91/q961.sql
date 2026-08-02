WITH aggregated AS (
    SELECT
        i.i_brand AS brand,
        i.i_category AS category,
        s.s_division_name AS division,
        cd.cd_gender AS gender,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        MIN(cs.cs_sales_price) AS min_sales_price,
        MAX(cs.cs_sales_price) AS max_sales_price,
        (
            SELECT MAX(ii.i_current_price)
            FROM item ii
            WHERE ii.i_brand = i.i_brand
        ) AS max_brand_price
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
       AND sr.sr_customer_sk = c.c_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE
        i.i_brand = 'Brand1'
        AND i.i_category = 'Sports'
        AND cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'M'
        AND hd.hd_vehicle_count = 1
        AND s.s_state = 'CA'
        AND c.c_birth_year BETWEEN 1960 AND 1970
        AND ib.ib_upper_bound <= 50000
        AND sr.sr_return_amt > 0
        AND cs.cs_sales_price > 10
        AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_customer_sk = c.c_customer_sk
              AND sr2.sr_return_amt > 1000
        )
    GROUP BY ROLLUP (i.i_brand, i.i_category, s.s_division_name, cd.cd_gender)
)
SELECT
    brand,
    category,
    division,
    gender,
    total_net_paid,
    total_return_amt,
    distinct_orders,
    avg_discount,
    min_sales_price,
    max_sales_price,
    max_brand_price,
    ROW_NUMBER() OVER (PARTITION BY brand ORDER BY total_net_paid DESC) AS brand_rank
FROM aggregated
WHERE total_net_paid IS NOT NULL
ORDER BY brand, division, gender, brand_rank
LIMIT 100
