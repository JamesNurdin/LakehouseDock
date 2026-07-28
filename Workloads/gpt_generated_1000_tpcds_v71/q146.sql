WITH sales_agg AS (
    SELECT
        ca.ca_state AS state,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_list_price) AS avg_ext_list_price,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND hd.hd_buy_potential <> 'Unknown'
      AND ca.ca_gmt_offset BETWEEN -5.00 AND 5.00
    GROUP BY ca.ca_state, d.d_year
)
SELECT
    state,
    year,
    total_net_profit,
    avg_ext_list_price,
    transaction_count,
    (
        SELECT MAX(i2.inv_quantity_on_hand)
        FROM inventory i2
        JOIN date_dim d2 ON i2.inv_date_sk = d2.d_date_sk
        WHERE d2.d_year = sales_agg.year
    ) AS max_inventory_qty_year
FROM sales_agg
WHERE total_net_profit > 100000
  AND avg_ext_list_price > 5000
  AND transaction_count >= 50
ORDER BY total_net_profit DESC
LIMIT 100
