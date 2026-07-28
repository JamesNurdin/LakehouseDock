WITH filtered_sales AS (
    SELECT
        cs.cs_net_paid_inc_ship_tax AS net_paid,
        cs.cs_order_number AS order_num,
        ca.ca_state,
        ca.ca_city,
        i.i_item_desc,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        d.d_year,
        REGEXP_EXTRACT(i.i_item_desc, '(?i)brand[: ]+([A-Za-z0-9]+)', 1) AS brand_extracted
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2000
      AND ca.ca_city LIKE 'A%'
      AND REGEXP_LIKE(i.i_item_desc, '(?i)electronic')
)
SELECT
    ca_state,
    brand_extracted,
    ib_lower_bound,
    ib_upper_bound,
    SUM(net_paid) AS total_sales,
    COUNT(DISTINCT order_num) AS distinct_orders
FROM filtered_sales
GROUP BY ca_state, brand_extracted, ib_lower_bound, ib_upper_bound
ORDER BY total_sales DESC
LIMIT 100
