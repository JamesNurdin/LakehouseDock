WITH sales_enriched AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_net_paid,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        i.i_formulation,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_college_count,
        ca.ca_state,
        ca.ca_location_type,
        COALESCE(inv.inv_quantity_on_hand, 0) AS quantity_on_hand
    FROM store_sales ss
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    WHERE (
            ca.ca_state = 'CA' OR ca.ca_state IS NULL
          )
      AND (
            ca.ca_location_type = 'apartment' OR ca.ca_location_type IS NULL
          )
      AND cd.cd_gender = 'F'
      AND cd.cd_marital_status = 'M'
      AND i.i_current_price BETWEEN 10 AND 100
      AND ss.ss_net_profit > 0
      AND COALESCE(inv.inv_quantity_on_hand, 0) > 0
)
SELECT
    se.i_brand,
    se.i_category,
    se.i_item_id,
    CASE 
        WHEN se.ss_net_profit > 1000 THEN 'High'
        WHEN se.ss_net_profit > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    se.quantity_on_hand,
    se.ss_quantity,
    se.ss_net_profit,
    -- scalar subquery: average profit for the same item across all sales
    (SELECT AVG(ss_sub.ss_net_profit)
       FROM store_sales ss_sub
       WHERE ss_sub.ss_item_sk = se.ss_item_sk) AS avg_item_profit,
    ROW_NUMBER() OVER (PARTITION BY se.i_brand ORDER BY se.ss_net_profit DESC) AS brand_profit_rank
FROM sales_enriched se
ORDER BY brand_profit_rank
LIMIT 100
