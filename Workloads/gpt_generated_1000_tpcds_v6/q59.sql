WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        CASE WHEN cs.cs_ext_tax > 100 THEN 'HighTax' ELSE 'LowTax' END AS tax_group,
        SUM(cs.cs_net_paid) AS amount,
        SUM(cs.cs_quantity) AS quantity,
        'sales' AS source
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk >= 5
    GROUP BY i.i_category,
        CASE WHEN cs.cs_ext_tax > 100 THEN 'HighTax' ELSE 'LowTax' END
),
returns_agg AS (
    SELECT
        i.i_category AS category,
        CASE WHEN sr.sr_return_amt > 500 THEN 'HighReturn' ELSE 'LowReturn' END AS tax_group,
        SUM(sr.sr_return_amt) AS amount,
        SUM(sr.sr_return_quantity) AS quantity,
        'store_return' AS source
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk >= 5
    GROUP BY i.i_category,
        CASE WHEN sr.sr_return_amt > 500 THEN 'HighReturn' ELSE 'LowReturn' END
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY category, tax_group, amount DESC
LIMIT 100
