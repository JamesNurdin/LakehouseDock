WITH item_sales AS (
    SELECT
        cs.cs_item_sk,
        i.i_item_id AS item_id,
        i.i_brand AS i_brand,
        i.i_category AS i_category,
        ca.ca_state AS ca_state,
        hd.hd_income_band_sk AS hd_income_band_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_ext_wholesale_cost) AS avg_wholesale_cost,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_fee) AS total_fee
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ext_wholesale_cost > 500.00
      AND cs.cs_ext_ship_cost BETWEEN 100.00 AND 3000.00
      AND hd.hd_income_band_sk IN (1, 9, 11)
      AND ca.ca_state = 'CA'
      AND i.i_brand = 'BrandA'
    GROUP BY cs.cs_item_sk, i.i_item_id, i.i_brand, i.i_category, ca.ca_state, hd.hd_income_band_sk
)
SELECT
    item_id,
    i_brand,
    i_category,
    ca_state,
    hd_income_band_sk,
    total_net_paid,
    total_return_amt,
    order_cnt,
    avg_wholesale_cost
FROM item_sales
WHERE total_net_paid > (
    SELECT AVG(total_net_paid) * 1.2
    FROM item_sales
)
ORDER BY total_net_paid DESC
LIMIT 100
