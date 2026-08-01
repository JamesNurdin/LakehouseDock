WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_item_sk,
        cs.cs_bill_hdemo_sk
    FROM
        catalog_sales cs
    WHERE
        cs.cs_quantity > 5
        AND cs.cs_sales_price >= 100.00
        AND cs.cs_ext_discount_amt > 0
        AND cs.cs_ext_sales_price > 1000.00
        AND cs.cs_ext_sales_price < 50000.00
)
SELECT
    i.i_brand,
    i.i_category,
    hd.hd_buy_potential,
    td.t_hour,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    SUM(fs.cs_quantity) AS total_quantity,
    AVG(fs.cs_ext_discount_amt) AS avg_discount,
    COUNT(*) AS num_sales,
    MAX(fs.cs_net_profit) AS max_profit
FROM
    filtered_sales fs
    JOIN time_dim td ON fs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON fs.cs_bill_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT
            i.i_brand,
            i.i_category,
            i.i_current_price,
            i.i_manufact_id,
            i.i_rec_end_date
        FROM
            item i
        WHERE
            i.i_item_sk = fs.cs_item_sk
            AND i.i_current_price BETWEEN 10.00 AND 500.00
            AND i.i_manufact_id IN (995, 630)
            AND i.i_rec_end_date = DATE '2000-10-26'
    ) i
WHERE
    EXISTS (
        SELECT 1
        FROM income_band ib
        WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
          AND ib.ib_upper_bound >= 150000
          AND ib.ib_lower_bound <= 200000
    )
    AND hd.hd_buy_potential = '>10000'
    AND hd.hd_dep_count <= 3
    AND td.t_hour BETWEEN 9 AND 17
GROUP BY
    i.i_brand,
    i.i_category,
    hd.hd_buy_potential,
    td.t_hour
HAVING
    SUM(fs.cs_ext_sales_price) > 10000
    AND COUNT(*) >= 10
ORDER BY
    total_sales DESC
LIMIT 100
