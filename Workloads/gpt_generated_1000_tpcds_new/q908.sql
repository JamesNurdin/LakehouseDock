WITH sampled_sales AS (
    SELECT ss_sold_date_sk,
           ss_sold_time_sk,
           ss_item_sk,
           ss_customer_sk,
           ss_cdemo_sk,
           ss_hdemo_sk,
           ss_addr_sk,
           ss_store_sk,
           ss_promo_sk,
           ss_ticket_number,
           ss_quantity,
           ss_wholesale_cost,
           ss_list_price,
           ss_sales_price,
           ss_ext_discount_amt,
           ss_ext_sales_price,
           ss_ext_wholesale_cost,
           ss_ext_list_price,
           ss_ext_tax,
           ss_coupon_amt,
           ss_net_paid,
           ss_net_paid_inc_tax,
           ss_net_profit
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_sales_price > 20
      AND ss_quantity >= 1
      AND ss_net_profit > 0
      AND ss_ext_discount_amt < 30
),
joined AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        ca.ca_location_type,
        ss.ss_addr_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_sales_price,
        ss.ss_quantity
    FROM sampled_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
),
agg_city AS (
    SELECT
        ca_city,
        ca_state,
        MIN(ss_addr_sk) AS exemplar_addr_sk,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count
    FROM joined
    WHERE ca_location_type <> 'condo'
    GROUP BY ca_city, ca_state
),
filtered AS (
    SELECT *
    FROM agg_city
    WHERE total_profit > 1000
      AND total_sales > 5000
      AND txn_count >= 5
      AND ca_state <> 'TX'
      AND ca_city NOT LIKE 'A%'
),
single_family_keys AS (
    SELECT ca_address_sk
    FROM customer_address
    WHERE ca_location_type = 'single family'
),
apartment_keys AS (
    SELECT ca_address_sk
    FROM customer_address
    WHERE ca_location_type = 'apartment'
),
diff_keys AS (
    SELECT ca_address_sk FROM single_family_keys
    EXCEPT
    SELECT ca_address_sk FROM apartment_keys
)
SELECT
    AVG(total_profit) AS avg_total_profit,
    AVG(total_sales) AS avg_total_sales,
    SUM(txn_count) AS total_transactions
FROM filtered f
WHERE NOT EXISTS (
    SELECT 1
    FROM diff_keys d
    WHERE d.ca_address_sk = f.exemplar_addr_sk
)
