WITH
    -- Aliased dimension tables (each alias will be joined separately)
    cd_bill AS (SELECT * FROM customer_demographics),
    cd_ship AS (SELECT * FROM customer_demographics),
    cd_refunded AS (SELECT * FROM customer_demographics),
    cd_returning AS (SELECT * FROM customer_demographics),
    cd_wr_returning AS (SELECT * FROM customer_demographics),
    ca_bill AS (SELECT * FROM customer_address),
    ca_ship AS (SELECT * FROM customer_address),
    ca_refunded AS (SELECT * FROM customer_address),
    ca_returning AS (SELECT * FROM customer_address),
    ca_wr_returning AS (SELECT * FROM customer_address),
    hd_bill AS (SELECT * FROM household_demographics),
    hd_ship AS (SELECT * FROM household_demographics),
    hd_refunded AS (SELECT * FROM household_demographics),
    hd_returning AS (SELECT * FROM household_demographics),
    hd_wr_returning AS (SELECT * FROM household_demographics),
    hd_wr_refunded AS (SELECT * FROM household_demographics),
    ib AS (SELECT * FROM income_band)
SELECT
    cs.cs_order_number,
    cd_bill.cd_gender AS billed_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cs.cs_ext_sales_price)                       AS total_catalog_sales,
    SUM(cr.cr_return_amount)                         AS total_catalog_returns,
    SUM(wr.wr_return_amt)                            AS total_web_returns,
    SUM(ss.ss_ext_sales_price)                       AS total_store_sales,
    COUNT(DISTINCT cs.cs_item_sk)                    AS distinct_items_sold,
    CASE
        WHEN SUM(cr.cr_return_amount) > 0 THEN 'Has Catalog Return'
        ELSE 'No Catalog Return'
    END                                            AS catalog_return_flag
FROM catalog_sales cs
-- join billed customer demographics / address / household
JOIN cd_bill      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN ca_bill      ON cs.cs_bill_addr_sk  = ca_bill.ca_address_sk
JOIN hd_bill      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
-- join shipped customer demographics / address / household
JOIN cd_ship      ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN ca_ship      ON cs.cs_ship_addr_sk  = ca_ship.ca_address_sk
JOIN hd_ship      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
-- catalog returns and its related dimensions
JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk      = cs.cs_item_sk
JOIN cd_refunded   ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN ca_refunded   ON cr.cr_refunded_addr_sk  = ca_refunded.ca_address_sk
JOIN hd_refunded   ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN cd_returning  ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN ca_returning  ON cr.cr_returning_addr_sk  = ca_returning.ca_address_sk
JOIN hd_returning  ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
-- store sales linked via the same billed dimensions
JOIN store_sales ss
      ON ss.ss_cdemo_sk = cd_bill.cd_demo_sk
     AND ss.ss_hdemo_sk = hd_bill.hd_demo_sk
     AND ss.ss_addr_sk  = ca_bill.ca_address_sk
-- left‑join web returns (outer join) through refunded demographics
LEFT JOIN web_returns wr
       ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN cd_wr_returning   ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
LEFT JOIN ca_wr_returning   ON wr.wr_returning_addr_sk  = ca_wr_returning.ca_address_sk
LEFT JOIN hd_wr_returning   ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
LEFT JOIN hd_wr_refunded    ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
-- left‑join income band (outer join) to the billed household
LEFT JOIN ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE cs.cs_sold_date_sk BETWEEN 2451556 AND 2451797   -- example date‑range filter on a surrogate key
GROUP BY
    cs.cs_order_number,
    cd_bill.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_catalog_sales DESC
LIMIT 100
