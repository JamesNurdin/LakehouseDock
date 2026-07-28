WITH sales_filtered AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        ca.ca_address_id,
        regexp_extract(ca.ca_address_id, '(\\d+)$') AS address_suffix,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2002
      AND regexp_like(i.i_product_name, '(?i)USB|Cable')
      AND ca.ca_address_id LIKE 'AAAAAAA%'
      AND ca.ca_city LIKE '%York%'
      AND ca.ca_gmt_offset = -5.00
), max_price_per_item AS (
    SELECT i_item_sk, MAX(i_current_price) AS max_price
    FROM item
    GROUP BY i_item_sk
)
SELECT
    sf.ca_state,
    COUNT(DISTINCT sf.i_item_id) AS distinct_items_sold,
    SUM(sf.ss_ext_sales_price) AS total_sales,
    SUM(sf.ss_net_profit) AS total_profit,
    AVG(CAST(sf.ib_lower_bound AS DOUBLE)) AS avg_income_lower,
    MIN(sf.address_suffix) AS min_address_suffix,
    CONCAT(sf.ca_state, '-', sf.address_suffix) AS state_suffix,
    SUBSTRING(sf.ca_city, 1, 3) AS city_prefix,
    (SELECT max_price FROM max_price_per_item mpi WHERE mpi.i_item_sk = sf.i_item_sk) AS item_max_price
FROM sales_filtered sf
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory inv
    WHERE inv.inv_item_sk = sf.i_item_sk
      AND inv.inv_date_sk = sf.ss_sold_date_sk
      AND inv.inv_quantity_on_hand > 500
)
GROUP BY sf.ca_state, sf.ca_city, sf.address_suffix, sf.i_item_sk
HAVING SUM(sf.ss_ext_sales_price) > 10000
ORDER BY total_profit DESC
LIMIT 100
