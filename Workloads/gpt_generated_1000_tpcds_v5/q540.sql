WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_net_profit,
        wr.wr_return_amt,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        d.d_year,
        cc.cc_division_name,
        cp.cp_type,
        ca.ca_state,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                         AND inv.inv_item_sk = i.i_item_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                               AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND ca.ca_state = 'CA'
      AND ss.ss_sales_price > 50
      AND inv.inv_quantity_on_hand > 0
),
agg AS (
    SELECT
        d_year,
        i_category,
        i_brand,
        cc_division_name,
        cp_type,
        COUNT(*) AS txn_count,
        SUM(ss_sales_price) AS total_sales,
        AVG(ss_sales_price) AS avg_sales,
        SUM(ss_net_profit) AS total_profit,
        SUM(wr_return_amt) AS total_returns,
        (
            SELECT MAX(i2.i_current_price)
            FROM item i2
            WHERE i2.i_category = base.i_category
        ) AS max_price_in_category
    FROM base
    GROUP BY d_year, i_category, i_brand, cc_division_name, cp_type
)
SELECT
    d_year,
    i_category,
    i_brand,
    cc_division_name,
    cp_type,
    txn_count,
    total_sales,
    avg_sales,
    total_profit,
    total_returns,
    max_price_in_category,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS category_sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
