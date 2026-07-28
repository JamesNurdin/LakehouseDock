WITH joined_data AS (
    SELECT
        d.d_year,
        d.d_following_holiday,
        d.d_last_dom,
        ca.ca_city,
        ca.ca_state,
        ca.ca_street_name,
        ca.ca_street_number,
        i.i_category,
        i.i_color,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_return_amt,
        sr.sr_return_ship_cost,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_following_holiday = 'N'
      AND d.d_last_dom = 2415567
      AND ca.ca_street_name = 'Pine Oak'
      AND ca.ca_street_number = '675       '
      AND sr.sr_return_ship_cost > 50
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns r2
          WHERE r2.sr_customer_sk = ss.ss_customer_sk
            AND r2.sr_return_amt > 200
      )
)
SELECT
    d_year,
    i_category,
    ca_city,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(sr_return_amt) AS total_returns,
    COUNT(DISTINCT ss_ticket_number) AS num_transactions,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
    MIN(ss_net_profit) AS min_profit,
    MAX(ss_net_profit) AS max_profit
FROM joined_data
GROUP BY d_year, i_category, ca_city
ORDER BY total_sales DESC
LIMIT 100
