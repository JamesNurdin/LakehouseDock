WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT DISTINCT
    ws.ws_sold_date_sk AS sold_date_key,
    i.i_item_id,
    i.i_product_name,
    ws.ws_net_paid,
    st.s_store_name,
    ca.ca_state,
    inv_agg.total_on_hand,
    (
        SELECT SUM(cs.cs_net_profit)
        FROM catalog_sales cs
        WHERE cs.cs_item_sk = i.i_item_sk
    ) AS catalog_item_profit,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY ws.ws_net_profit DESC) AS state_profit_rank,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ws.ws_sold_date_sk) AS state_row_num
FROM web_sales ws
JOIN time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN store_sales ss
  ON ss.ss_sold_time_sk = td.t_time_sk
 AND ss.ss_item_sk = i.i_item_sk
JOIN store st
  ON ss.ss_store_sk = st.s_store_sk
JOIN catalog_sales cs
  ON cs.cs_sold_time_sk = td.t_time_sk
 AND cs.cs_item_sk = i.i_item_sk
 AND cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN inv_agg
  ON inv_agg.inv_item_sk = i.i_item_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND ca.ca_location_type = 'condo'
  AND i.i_category = 'Electronics'
  AND wsite.web_country = 'United States'
ORDER BY state_profit_rank ASC, ws.ws_sold_date_sk DESC
LIMIT 100
