SELECT
    cs.cs_order_number,
    d.d_year,
    cd.cd_gender,
    sm.sm_type,
    hd.hd_buy_potential,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    COUNT(*) AS line_item_cnt,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_category
FROM
    tpcds.catalog_sales cs
JOIN
    tpcds.date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
JOIN
    tpcds.customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN
    tpcds.customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN
    tpcds.household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN
    tpcds.ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN
    tpcds.store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
     AND ss.ss_customer_sk = c.c_customer_sk
WHERE
    d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND hd.hd_income_band_sk IN (11, 13)
    AND sm.sm_type = 'AIR'
    AND cd.cd_gender = 'M'
    AND cs.cs_quantity > 5
    AND cs.cs_order_number NOT IN (
        SELECT cs_sub.cs_order_number
        FROM tpcds.catalog_sales cs_sub
        WHERE cs_sub.cs_quantity = 0
    )
GROUP BY
    cs.cs_order_number,
    d.d_year,
    cd.cd_gender,
    sm.sm_type,
    hd.hd_buy_potential
ORDER BY
    total_net_paid DESC
LIMIT 100
