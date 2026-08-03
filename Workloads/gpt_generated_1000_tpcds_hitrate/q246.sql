WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_date_sk, inv_warehouse_sk
),
avg_discount AS (
    SELECT AVG(ss_ext_discount_amt) AS overall_avg_discount
    FROM store_sales
)
SELECT
    d.d_year,
    s.s_store_name,
    ca.ca_state,
    cd.cd_gender,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    SUM(i.total_qty) AS total_inventory_qty,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    (SELECT overall_avg_discount FROM avg_discount) AS overall_avg_discount,
    SUM(SUM(ss.ss_ext_sales_price)) OVER (
        PARTITION BY d.d_year
        ORDER BY s.s_store_name
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_sales
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_store_sk = s.s_store_sk
   AND sr.sr_cdemo_sk = cd.cd_demo_sk
   AND sr.sr_addr_sk = ca.ca_address_sk
JOIN inv_agg i
    ON i.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND ca.ca_country = 'United States'
  AND cd.cd_gender = 'M'
  AND cd.cd_purchase_estimate >= 5000
  AND ss.ss_ext_sales_price > 500
GROUP BY ROLLUP (d.d_year, s.s_store_name, ca.ca_state, cd.cd_gender)
ORDER BY d.d_year ASC, s.s_store_name ASC, ca.ca_state ASC, cd.cd_gender ASC
LIMIT 100
