WITH monthly_high AS (
    SELECT
        cp.cp_type AS catalog_type,
        hd.hd_buy_potential AS buy_potential,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_type = 'monthly'
      AND hd.hd_buy_potential = '>10000'
    GROUP BY cp.cp_type, hd.hd_buy_potential
),
quarterly_low AS (
    SELECT
        cp.cp_type AS catalog_type,
        hd.hd_buy_potential AS buy_potential,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_type = 'quarterly'
      AND hd.hd_buy_potential IN ('501-1000', 'Unknown')
    GROUP BY cp.cp_type, hd.hd_buy_potential
)
SELECT
    catalog_type,
    buy_potential,
    total_sales,
    total_quantity
FROM monthly_high
UNION ALL
SELECT
    catalog_type,
    buy_potential,
    total_sales,
    total_quantity
FROM quarterly_low
ORDER BY total_sales DESC
